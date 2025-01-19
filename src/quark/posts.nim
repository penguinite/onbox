# Copyright © penguinite 2024 <penguinite@tuta.io>
#
# This file is part of Pothole.
# 
# Pothole is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Pothole is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Pothole. If not, see <https://www.gnu.org/licenses/>. 
#
# quark/new/post.nim:
## This module contains all the logic for handling posts.
## 
## Including basic processing, database storage,
## database retrieval, modification, deletion and so on
## and so forth.

# From Quark
import quark/private/[macros, database]
import quark/[strextra, shared, tag]
export shared

# From the standard library
import std/[tables, times]
from std/strutils import split

# From elsewhere
import db_connector/db_postgres, rng

export Post, PostPrivacyLevel, PostContent, PostContentType

# Game plan when inserting a post:
# Insert the post
# Insert the post content
#
# Game plan when post is edited (text only):
# Create a new "text content" row in the db
# Update any other columns accordingly (Setting latest to false)
# Create a new "post content" row in the db and set it accordingly.
# Update any other attributes accordingly (For example, the client, the modified bool, the recipients, the level)
# 
# Game plan when post is edited (For non-archived types of content, such as polls):
# Remove existing content row
# Create new one

proc newPost*(sender: string, content: seq[PostContent], replyto: string = "", recipients: seq[string] = @[], local = true, written: DateTime = now().utc): Post =
  if isEmptyOrWhitespace(sender):
    raise newException(ValueError, "Post is missing sender field.")

  if len(content) == 0:
    raise newException(ValueError, "Post is missing content field.")

  # Generate post id
  result.id = randstr(32)
  
  # Just do this stuff...
  result.sender = sender
  result.recipients = recipients
  result.local = local
  result.modified = false
  result.content = content
  result.replyto = replyto
  result.written = written
  result.level = Public
  result.client = "0"

  return result

proc newPostX*(
  sender: string, content: seq[PostContent], recipients: seq[string] = @[],
  id: string = randstr(32), replyto: string = "", written: DateTime = now().utc, modified: bool = false,
  local: bool = true, client: string = "0", level: PostPrivacyLevel = Public,
  reactions: Table[string, seq[string]] = initTable[string,seq[string]](),
  boosts: Table[string, seq[string]] = initTable[string,seq[string]]()
): Post =
  result.id = id
  result.recipients = recipients
  result.sender = sender
  result.replyto = replyto
  result.content = content
  result.written = written
  result.modified = modified
  result.local = local
  result.client = client
  result.level = level
  result.reactions = reactions
  result.boosts = boosts
  return result

proc text*(content: string, date: DateTime = now().utc, format = "plain"): PostContent =
  result = PostContent(kind: Text)
  result.text = content
  result.published = date
  result.format = format
  return result

proc constructPost*(db: DbConn, row: Row): Post =
  ## Converts a post minimally.
  ## This means no reactions list, no boost list
  ## and no post content.
  ## 
  ## If you need all those bits of data then use constructPostFull() instead.
  ## 
  ## If you need *just* the post and its content then use constructPostSemi() instead.
  
  var i: int = -1;

  for key,value in result.fieldPairs:
    # Skip the fields that are processed by *other* bits of code.
    when result.get(key) isnot Table[string, seq[string]] and result.get(key) isnot seq[PostContent]:
      inc(i)

    when result.get(key) is bool:
      result.get(key) = parseBool(row[i])
    when result.get(key) is string:
      result.get(key) = row[i]
    when result.get(key) is seq[string]:
      result.get(key) = split(row[i], ",")

      # the split() proc sometimes creates items in the sequence
      # even when there isn't. So this bit of code manually
      # clears the list if two specific conditions are met.
      if len(result.get(key)) == 1 and result.get(key)[0] == "":
        result.get(key) = @[]
    when result.get(key) is DateTime:
      result.get(key) = toDateFromDb(row[i])
    when result.get(key) is PostPrivacyLevel:
      result.get(key) = toPrivacyLevelFromDb(row[i])
  return result

proc constructPostSemi*(db:DbConn, row: Row): Post =
  result = db.constructPost(row)
  return result

proc constructPostFull*(db: DbConn, row: Row): Post =
  result = db.constructPostSemi(row)
  #result.reactions = db.getReactions(result.id)
  #result.boosts = db.getBoosts(result.id)
  return result

proc addPost*(db: DbConn, post: Post) =
  ## A function add a post into the database
  ## This function uses parameterized substitution
  ## So escaping objects before sending them here is not a requirement.
  
  let testStatement = sql"SELECT local FROM posts WHERE id = ?;"

  if db.getRow(testStatement, post.id).has():
    raise newException(DbError, "Post with id \"" & post.id & "\" already exists.")

  # TODO: Prettify this.
  db.exec(
    sql"INSERT INTO posts (id,recipients,sender,replyto,written,modified,local,client,level) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);",
    post.id,
    toDbString(post.recipients),
    post.sender,
    post.replyto,
    toDbString(post.written),
    post.modified,
    post.local,
    post.client,
    toDbString(post.level)
  )

  # Handle post "contents"
  for content in post.content:
    case content.kind:
    of Text:
      # Insert post text
      db.exec(
        sql"INSERT INTO posts_text (pid,content,format,published,latest) VALUES (?,?,?,?,?);",
        post.id, content.text, content.format, toDbString(content.published), true
      )

      # And then insert the post content
      db.exec(
        sql"INSERT INTO posts_content (pid,kind,cid) VALUES (?,?,?);",
        post.id, "0", ""
      )
    of Tag:
      # Hashtag usage is just tracked by inserting a value into the posts_tag table

      # So first, we check if the hashtag exists in the first place.
      # Creating it if it doesn't. Cause there's a foreign_key on posts_tag.tag
      if not db.tagExists(content.tag_used):
        db.createTag(content.tag_used)
      db.exec(
        sql"INSERT INTO posts_tag VALUES (?,?,?,?);",
        post.id, content.tag_used, post.sender, toDbString(content.tag_date)
      )
    else:
      # If you encounter this error then flag it immediately to the devs.
      raise newException(DbError, "Unknown post content type: " & $(content.kind))

proc postIdExists*(db: DbConn, id: string): bool =
  ## A function to see if a post id exists in the database
  ## The id supplied can be plain and un-escaped. It will be escaped and sanitized here.
  return has(db.getRow(sql"SELECT local FROM posts WHERE id = ?;", id))

proc updatePost*(db: DbConn, id, column, value: string) =
  ## A procedure to update a post using it's ID.
  ## Like with the updateUserByHandle and updateUserById procedures,
  ## the value parameter should be heavily sanitized and escaped to prevent a class of awful security holes.
  ## The id can be passed plain, it will be escaped.
  db.exec(sql("UPDATE posts SET " & column & " = ? WHERE id = ?;"), value, id)

proc getPost*(db: DbConn, id: string): Row =
  ## Retrieve a post using an ID.
  ## 
  ## You will need to pass this on further to constructPost()
  ## or it's semi and full variants. As this just returns a database row.
  let post = db.getRow(sql"SELECT * FROM posts WHERE id = ?;", id)
  if not post.has():
    raise newException(DbError, "Couldn't find post with id \"" & id & "\"")
  return post

proc getPostIDsByUser*(db: DbConn, id: string, limit: int = 15): seq[string] = 
  ## A procedure that only fetches the IDs of posts made by a specific user.
  ## This is used to quickly get a list over every post made by a user, for, say,
  ## potholectl or a pothole admin frontend.
  var sqlStatement = sql"SELECT id FROM posts WHERE sender = ?;"
  if limit != 0:
    sqlStatement = sql("SELECT id FROM posts WHERE sender = ? LIMIT " & $limit & ";")

  for post in db.getAllRows(sqlStatement, id):
    result.add(post[0])
  return result

proc getEveryPostByUser*(db: DbConn, id:string, limit: int = 20): seq[Post] =
  ## A procedure to get any user's posts using the user's id.
  ## The limit parameter dictates how many posts to retrieve, set the limit to 0 to retrieve all posts.
  ## All of the posts returned are fully ready for displaying and parsing
  ## *Note:* This procedure returns every post, even private ones. For public posts, use getPostByUserId()
  var sqlStatement = ""
  if limit != 0:
    sqlStatement = "SELECT * FROM posts WHERE id = ? LIMIT " & $limit & ";"
  else:
    sqlStatement = "SELECT * FROM posts WHERE id = ?;"
  
  for post in db.getAllRows(sql(sqlStatement), id):
      result.add(db.constructPostSemi(post))
  return result

proc getPostsByUser*(db: DbConn, id:string, limit: int = 20): seq[Post] =
  ## A procedure to get any user's posts using the user's id.
  ## The limit parameter dictates how many posts to retrieve, set the limit to 0 to retrieve all posts.
  ## All of the posts returned are fully ready for displaying and parsing
  ## *Note:* This procedure only returns posts that are public. For private posts, use getEveryPostByUserId()
  var sqlStatement = ""
  if limit != 0:
    sqlStatement = "SELECT * FROM posts WHERE sender = ? LIMIT " & $limit & ";"
  else:
    sqlStatement = "SELECT * FROM posts WHERE sender = ?;"
  
  for post in db.getAllRows(sql(sqlStatement), id):
    # Check for if post is unlisted or public, only then can we add it into the list.
    let postObj = db.constructPostFull(post)
    if postObj.level == Public or postObj.level == Unlisted:
      result.add(postObj)

  return result

proc getPostsByUserIDPaginated*(db: DbConn, id:string, offset: int, limit: int = 15): seq[Post] =
  ## A procedure to get posts made by a specific user, this procedure is specifically optimized for pagination.
  ## In that, it supports with offsets, limits and whatnot.
  return # TODO: Implement

proc getNumPostsByUser*(db: DbConn, id: string): int =
  result = 0
  for row in db.getAllRows(sql"SELECT local FROM posts WHERE sender = ?;", id):
    inc(result)
  return result


proc getNumTotalPosts*(db: DbConn, local = true): int =
  ## A procedure to get the total number of local posts.
  result = 0
  for x in db.getAllRows(sql("SELECT local FROM posts WHERE local = " & $local & ";")):
    inc(result)
  return result

proc deletePost*(db: DbConn, id: string) = 
  db.exec(sql"DELETE FROM posts WHERE id = ?;", id)

proc deletePosts*(db: DbConn, sequence: seq[string]) =
  for id in sequence:    
    db.deletePost(id)

proc reassignSenderPost*(db: DbConn, post_id, sender: string) =
  db.exec(sql"UPDATE posts SET sender = ? WHERE id = ?;", sender, post_id)

proc getNumOfReplies*(db: DbConn, post_id: string): int =
  for i in db.getAllRows(sql"SELECT id FROM posts WHERE replyto = ?;", post_id):
    inc(result)
  return result

proc getPostSender*(db: DbConn, post_id: string): string =
  return db.getRow(sql"SELECT sender FROM posts WHERE id = ?;", post_id)[0]

proc reassignSenderPosts*(db: DbConn, post_ids: seq[string], sender: string) =
  for post_id in post_ids:
    db.reassignSenderPost(post_id, sender)

proc getLocalPosts*(db: DbConn, limit: int = 15): seq[Row] =
  ## A procedure to get posts from local users only.
  ## Set limit to 0 to disable the limit and get all posts from local users.
  ## 
  ## This returns seq[Row], so you might want to pass it on to a constructPost() like proc.
  
  var sqlStatement: SqlQuery
  if limit != 0:
    sqlStatement = sql("SELECT * FROM posts WHERE local = TRUE LIMIT " & $limit & ";")
  else:
    sqlStatement = sql"SELECT * FROM posts WHERE local = TRUE;"
  
  for post in db.getAllRows(sqlStatement):
    result.add(post)
  return result
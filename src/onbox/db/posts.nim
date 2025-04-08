# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
#
# This file is part of Onbox.
# 
# Onbox is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Onbox is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Onbox. If not, see <https://www.gnu.org/licenses/>. 
#
# onbox/db/posts.nim:
## This module contains all the logic for handling posts.
## 
## Including basic processing, database storage,
## database retrieval, modification, deletion and so on
## and so forth.

# From Onbox
import private/utils, ../[strextra, shared], follows

# From the standard library
import std/[tables, times, strutils]

# From elsewhere
import db_connector/db_postgres, rng

# Game plan when inserting a post:
# Insert the post
# Insert the post content
#
# Game plan when post is edited (text only):
# Create a new "text content" row in the db
# Update any other columns accordingly (Setting latest to false)
# Create a new "post content" row in the db and set it accordingly.
# Update any other attributes accordingly (For example, the client, the modified bool, the recipients, the level)

proc constructPost*(db: DbConn, row: Row): Post =
  ## Constructs a post out of a database row, minimally.
  ## This means no reactions, no boosts
  ## and no content.  
  var i: int = -1;
  for key,value in result.fieldPairs:
    # Skip the fields that are processed by *other* bits of code.
    when result.get(key) isnot Table[string, seq[string]] and result.get(key) isnot seq[PostContent]:
      inc(i)

    when result.get(key) is bool:
      result.get(key) = (row[i] == "t")
    when result.get(key) is string:
      result.get(key) = row[i]
    when result.get(key) is seq[string]:
      result.get(key) = toStrSeq(row[i])
    when result.get(key) is DateTime:
      result.get(key) = toDate(row[i])
    when result.get(key) is PostPrivacyLevel:
      result.get(key) = toLevel(row[i])

proc newPost*(): Post =
  result.id = rng.uuidv4()

proc addPost*(db: DbConn, post: Post) =
  ## A function to add a post into the database
  db.exec(
    sql"INSERT INTO posts VALUES (?,?,NULLIF(?,'')::UUID,NULLIF(?,'')::UUID,?,?,?,?,?);",
    post.id,
    post.sender,
    post.replyto,
    post.client,
    !$(post.written),
    $(post.level),
    post.local,
    !$(post.recipients),
    !$(post.tags)
  )

  # Handle post "contents"
  for content in post.content:
    case content.kind:
    of Text:
      # Insert post text
      db.exec(
        sql"INSERT INTO post_texts VALUES (?,?,?,?);",
        post.id,
        !$(content.txt_published),
        $(content.txt_format),
        content.text,
      )
    else:
      # If you encounter this error then flag it immediately to the devs.
      raise newException(DbError, "Unknown post content type: " & $(content.kind))

proc postIdExists*(db: DbConn, id: string): bool =
  ## A function to see if a post id exists in the database
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM posts WHERE id = ?);", id
  )[0] == "t"

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
  ## or its semi and full variants. As this just returns a database row.
  db.getRow(sql"SELECT * FROM posts WHERE id = ?;", id)

proc getPostsByUser*(db: DbConn, id: string, limit: int = 15): seq[string] = 
  ## A procedure that only fetches the IDs of posts made by a specific user.
  ## This is used to quickly get a list over every post made by a user, for, say,
  ## onboxctl or an Onbox admin frontend.
  var sqlStatement = "SELECT id FROM posts WHERE sender = ?"

  if limit != 0: sqlStatement.add(" LIMIT " & $limit & ";")
  else: sqlStatement.add(";")

  for post in db.getAllRows(sql(sqlStatement), id):
    result.add(post[0])

proc getNumPostsByUser*(db: DbConn, id: string): int =
  ## Returns the number of posts made by a specific user.
  len(db.getAllRows(sql"SELECT 0 FROM posts WHERE sender = ?;", id))

proc getPostText*(db: DbConn, id: string): PostContent =
  ## Returns the latest draft/text of a post.
  let row = db.getRow(sql"SELECT published,format,content FROM post_texts WHERE pid = ? ORDER BY published DESC;", id)
  return PostContent(
    kind: Text,
    txt_published: toDate(row[0]),
    txt_format: parseInt(row[1]),
    text: row[2]
  )

proc getNumTotalPosts*(db: DbConn, local = true): int =
  ## A procedure to get the total number of posts. You can choose where or not they should be local-only with the local parameter.
  case local:
  of true: return len(db.getAllRows(sql("SELECT 0 FROM posts WHERE is_local = true;")))
  of false: return len(db.getAllRows(sql("SELECT 0 FROM posts;")))

proc deletePost*(db: DbConn, id: string) = 
  db.exec(sql"DELETE FROM posts WHERE id = ?;", id)
  db.exec(sql"DELETE FROM post_texts WHERE pid = ?;", id)

proc getNumOfReplies*(db: DbConn, post_id: string): int =
  len(db.getAllRows(sql"SELECT 0 FROM posts WHERE replyto = ?;", post_id))

proc getPostSender*(db: DbConn, post_id: string): string =
  db.getRow(sql"SELECT sender FROM posts WHERE id = ?;", post_id)[0]

proc updatePostSender*(db: DbConn, post_id, sender: string) =
  ## Updates the `sender` for any post
  ## 
  ## Used when deleting users, since we can save on processing costs
  ## by marking posts as "deleted" or "unavailable"
  ## (And this, we do by setting the sender to null)
  db.exec(sql"UPDATE posts SET sender = ? WHERE id = ?;", sender, post_id)

proc getLocalPosts*(db: DbConn, limit: int = 15): seq[string] =
  ## A procedure to get posts from local users only.
  ## Set limit to 0 to disable the limit and get all posts from local users.
  ## 
  ## This returns seq[Row], so you might want to pass it on to a constructPost() like proc.
  
  var sqlStatement = "SELECT id FROM posts WHERE is_local = TRUE"
  if limit != 0:
    sqlStatement.add(" LIMIT " & $limit)
  
  for post in db.getAllRows(sql(sqlStatement & ";")):
    result.add(post[0])

import packages/docutils/[rst, rstgen], std/strtabs

proc contentToHtml*(content: PostContent): string =
  ## Converts a PostContent object into safe, sanitized HTML. Ready for displaying!
  case content.kind:
  of Text:
    ## TODO: Add support for HTML, ie. do HTML sanitization the way that Mastodon does it.
    case content.txt_format:
    of 0: # Text, plain
      result.add("<p>" & htmlEscape(content.text) & "</p>")
    of 1: # Markdown
      result.add(rstToHtml(
          htmlEscape(content.text), {roPreferMarkdown}, newStringTable()
        )
      )
    of 2: # ReStructuredText
      result.add(
        rstToHtml(htmlEscape(content.text), {}, newStringTable())
      )
    else: raise newException(ValueError, "Unexpected text format: " & $(content.txt_format))
  else: raise newException(ValueError, "Unexpected content type: " & $(content.kind))

proc getPostPrivacyLevel*(db: DbConn, id: string): PostPrivacyLevel =
  toLevel(db.getRow(sql"SELECT level FROM posts WHERE id = ?;", id)[0])

proc getSender*(db: DbConn, pid: string): string =
  db.getRow(sql"SELECT sender FROM posts WHERE id = ?;", pid)[0]

proc getRecipients*(db: DbConn, pid: string): seq[string] =
  toStrSeq(db.getRow(sql"GET recipients FROM posts WHERE id = ?;", pid)[0])

proc canSeePost*(db: DbCOnn, uid, pid: string, level: PostPrivacyLevel): bool =
  case level:
  of Public, Unlisted:
    # Of course the user is allowed to see these...
    return true
  of FollowersOnly:
    # Check if user is following sender
    # If so, then yes, they can see the post.
    return db.getFollowStatus(uid, db.getSender(pid)) == AcceptedFollowRequest
  of Limited, Private:
    # TODO: Limited is different from Private but the MastoAPI docs don't clarify hpw.
    # Please figure out the difference and fix this bug.
    # For now, we will check if the user has been directly mentioned in the post they
    # want to see.
    return uid in db.getRecipients(pid)

proc idempotencyCheck*(db: DbConn, user, content: string): bool =
  ## Returns true if a user has written a post with this content
  ## an hour ago.
  ## TODO: THIS IS NOT TRUE IDEMPOTENCY!!!
  return false #TODO :Implemented
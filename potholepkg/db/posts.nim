# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
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
# db/sqlite/posts.nim:
## This module contains all database logic for handling posts.

# From somewhere in Pothole
import ../[post, user, lib]

# From somewhere in the standard library
import std/strutils except isEmptyOrWhitespace, parseBool
import std/[tables]

import common, reactions, boosts, users


const postsCols*: OrderedTable[string, string] = {
  "id": "TEXT PRIMARY KEY NOT NULL", #The Post id
  "recipients":"TEXT", # A comma-separated list of recipients since sqlite3 does not support arrays by default
  "sender":"TEXT NOT NULL", # A string containing the sender's id
  "replyto": "TEXT DEFAULT ''", # A string containing the post that the sender is replying to, if at all.
  "content": "TEXT NOT NULL DEFAULT ''", # A string containing the latest content of the post.
  "written":"TIMESTAMP NOT NULL", # A timestamp containing the date that the post was written (and published)
  "modified":"BOOLEAN NOT NULL DEFAULT FALSE", # A boolean indicating whether the post was modified or not.
  "local": "BOOLEAN NOT NULL", # A boolean indicating whether the post originated from this server or other servers.
  # TODO: This __A/__B hack is really, well, hacky. Maybe replace it?
  "__A": "foreign key (replyto) references posts(id)", # Some foreign key for integrity
  "__B": "foreign key (sender) references users(id)", # Same as above
}.toOrderedTable

## Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
#const postsCols*: OrderedTable[string, string] = {"id":"TEXT PRIMARY KEY NOT NULL", # The post Id

#}.toOrderedTable

proc constructPostFromRow*(db: DbConn, row: Row): Post =
  ## A procedure that takes a database Row (From the Posts table)
  ## And turns it into a Post object ready for display, parsing and so on. (That is to say, the final Post is unescaped and does not need further action.)
  ## Note: This does not include reactions or boosts. Fill those fields with getReactions() or getBoosts()
  result = Post()
  
  # This looks ugly, I know, I had to wrap it with
  # two specific functions but we don't have to re-write this
  # even if we add new things to the User object. EXCEPT!
  # if we introduce new data types to the User object
  var i: int = -1;

  for key,value in result.fieldPairs:
    when result.get(key) isnot Table[string, seq[string]]:
      inc(i)
    # If its string, add it surrounding quotes
    # Otherwise add it whole
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
      result.get(key) = toDate(row[i])

  result.reactions = db.getReactions(result.id)
  result.boosts = db.getBoosts(result.id)

  return result

proc addPost*(db: DbConn, post: Post): bool =
  ## A function add a post into the database
  ## This function uses parameterized substitution
  ## So escaping objects before sending them here is not a requirement.
  
  let testStatement = sql"SELECT local FROM posts WHERE id = ?;"

  if db.getRow(testStatement, post.id).has():
    return false # Someone has tried to add a post twice. We just won't add it.
  
  # TODO: Automate this some day.
  # I believe we can use a template or a macro to automate inserting this stuff in.
  try:
    let statement = sql"INSERT OR REPLACE INTO posts (id,recipients,sender,replyto,content,written,updated,modified,local,revisions) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
    db.exec(
      statement,
      post.id,
      toString(post.recipients),
      post.sender,
      post.replyto,
      post.content,
      toString(post.written),
      post.modified,
      post.local,
      toString(post.revisions)
    )
  except CatchableError as err:
    error "Failed to insert post: ", err.msg
  return true

proc postIdExists*(db: DbConn, id: string): bool =
  ## A function to see if a post id exists in the database
  ## The id supplied can be plain and un-escaped. It will be escaped and sanitized here.
  return has(db.getRow(sql"SELECT local FROM posts WHERE id = ?;", escape(id)))

proc updatePost*(db: DbConn, id, column, value: string): bool =
  ## A procedure to update a post using it's ID.
  ## Like with the updateUserByHandle and updateUserById procedures,
  ## the value parameter should be heavily sanitized and escaped to prevent a class of awful security holes.
  ## The id can be passed plain, it will be escaped.
  let statement = sql("UPDATE posts SET " & column & " = ? WHERE id = ?;")
  try:
    db.exec(statement, value, id)
    return true
  except:
    return false

proc getPost*(db: DbConn, id: string): Post =
  ## A procedure to get a post object using it's ID.
  ## The id can be passed plain, it will be escaped.
  ## The output will be an unescaped
  
  var post = db.getRow(sql"SELECT * FROM posts WHERE id = ?;", escape(id))
  if not post.has():
    error "Something or someone tried to retrieve a non-existent post with the ID of \"" & id & "\""

  result = db.constructPostFromRow(post)

  return result

proc getPostIDsByUserWithID*(db: DbConn, id: string, limit: int = 15): seq[string] = 
  ## A procedure that only fetches the IDs of posts made by a specific user.
  ## This is used to quickly get a list over every post made by a user, for, say,
  ## potholectl or a pothole admin frontend.
  let sqlStatement = sql"SELECT id FROM posts WHERE sender = ?;"
  if limit != 0:
    var i = 0;
    for post in db.getAllRows(sqlStatement, id):
      inc(i)
      result.add(post[0])
      if i > limit:
        break
  else:
    for post in db.getAllRows(sqlStatement, id):
      result.add(post[0])
  return result

proc getPostsByUserId*(db: DbConn, id:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts using the user's id.
  ## The limit parameter dictates how many posts to retrieve, set the limit to 0 to retrieve all posts.
  ## All of the posts returned are fully ready for displaying and parsing (They are unescaped.)
  let sqlStatement = sql"SELECT * FROM posts WHERE id = ?;"
  if limit != 0:
    var i = 0;
    for post in db.getAllRows(sqlStatement, id):
      inc(i)
      result.add(db.constructPostFromRow(post))
      if i > limit:
        break
  else:
    for post in db.getAllRows(sqlStatement, id):
      result.add(db.constructPostFromRow(post))
  return result

proc getPostsByUserHandle*(db: DbConn, handle:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts using the user's handle
  ## The handle can be passed plainly, it will be escaped later.
  ## The limit parameter dictates how many posts to retrieve, set the limit to 0 to retrieve all posts.
  ## All of the posts returned are fully ready for displaying and parsing (They are unescaped.)
  return db.getPostsByUserId(db.getIdFromHandle(sanitizeHandle(handle)), limit)

proc getTotalPosts*(db: DbConn): int =
  ## A procedure to get the total number of local posts.
  result = 0
  for x in db.getAllRows(sql"SELECT local FROM posts;"):
    inc(result)
  return result

proc deletePost*(db: DbConn, id: string): bool = 
  try:
    db.exec(sql"DELETE FROM posts WHERE id = ?;", id)
    return true
  except:
    return false

proc deletePosts*(db: DbConn, sequence: seq[string]): bool =
  for id in sequence:    
    if not db.deletePost(id):
      return false
  return true

proc reassignSenderPost*(db: DbConn, post_id, sender: string): bool =
  try:
    db.exec(sql"UPDATE posts SET sender = ? WHERE id = ?;", sender, post_id)
    return true
  except:
    return false

proc reassignSenderPosts*(db: DbConn, post_ids: seq[string], sender: string): bool =
  for post_id in post_ids:
    if not db.reassignSenderPost(post_id, sender):
      return false
  return true

proc getLocalPosts*(db: DbConn, limit: int = 15): seq[Post] =
  ## A procedure to get posts from local users only.
  ## Set limit to 0 to disable the limit and get all posts from local users.
  let statement = sql"SELECT * FROM posts WHERE local = true;"
  if limit != 0:
    for row in db.getAllRows(statement):
      if len(result) > limit:
        break
      result.add(db.constructPostFromRow(row))
  else:
    for row in db.getAllRows(statement):
      result.add(db.constructPostFromRow(row))
  return result
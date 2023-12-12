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
import std/strutils except isEmptyOrWhitespace
import std/[tables, options]

# From somewhere else (nimble etc.)
when (NimMajor, NimMinor, NimPatch) >= (1, 7, 3):
  include db_connector/db_postgres
else:
  include db_postgres

import common, reactions, boosts, users

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
const postsCols*: OrderedTable[string, string] = {"id":"TEXT PRIMARY KEY", # The post Id
"recipients":"TEXT", # A comma-separated list of recipients since sqlite3 does not support arrays by default
"sender":"TEXT NOT NULL", # A string containing the sender handle
"replyto": "TEXT", # A string containing the post that the sender is replying to, if at all.
"content": "TEXT", # A string containing the actual post's contents.
"written":"TIMESTAMP NOT NULL", # A timestamp containing the date that the post was written (and published)
"updated":"TIMESTAMP", # An optional timestamp containing the date that the post was updated
"modified":"BOOLEAN NOT NULL", # A boolean indicating whether the post was modified or not.
"local": "BOOLEAN NOT NULL", # A boolean indicating whether the post originated from this server or other servers.
"revisions": "TEXT", # A string containing previous revisions of a post
}.toOrderedTable

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
  ## This function uses parameterized substitution Aka. prepared statements.
  ## So escaping objects before sending them here is not a requirement.
  
  let testStatement = db.stmt("SELECT local FROM posts WHERE id = ?;")

  if testStatement.one(post.id).has():
    return false # Someone has tried to add a post twice. We just won't add it.
  
  # TODO: Automate this some day.
  # I believe we can use a template or a macro to automate inserting this stuff in.
  try:
    let statement = db.stmt("INSERT OR REPLACE INTO posts (id,recipients,sender,replyto,content,written,updated,modified,local,revisions) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);")
    statement.exec(
      post.id,
      toString(post.recipients),
      post.sender,
      post.replyto,
      post.content,
      toString(post.written),
      toString(post.updated),
      post.modified,
      post.local,
      toString(post.revisions)
    )
    statement.finalize()
  except CatchableError as err:
    error "Failed to insert post: ", err.msg

  

  return true

proc postIdExists*(db: DbConn, id: string): bool =
  ## A function to see if a post id exists in the database
  ## The id supplied can be plain and un-escaped. It will be escaped and sanitized here.
  return has(db.one("SELECT local FROM posts WHERE id = " & escape(id) & ";"))

proc updatePost*(db: DbConn, id, column, value: string): bool =
  ## A procedure to update a post using it's ID.
  ## Like with the updateUserByHandle and updateUserById procedures,
  ## the value parameter should be heavily sanitized and escaped to prevent a class of awful security holes.
  ## The id can be passed plain, it will be escaped.
  let statement = db.stmt("UPDATE posts SET " & column & " = ? WHERE id = ?;")
  try:
    statement.exec(value, id)
    statement.finalize()
    return true
  except:
    statement.finalize()
    return false
  

proc getPost*(db: DbConn, id: string): Post =
  ## A procedure to get a post object using it's ID.
  ## The id can be passed plain, it will be escaped.
  ## The output will be an unescaped
  
  var post = db.one("SELECT * FROM posts WHERE id = " & escape(id) & ";")
  if isNone(post):
    error "Something or someone tried to retrieve a non-existent post with the ID of \"" & id & "\""

  result = db.constructPostFromRow(post.get)

  return result

proc getPostsByUserHandle*(db: DbConn, handle:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts using the users handle
  ## The handle can be passed plainly, it will be escaped later.
  ## The limit parameter dictates how many posts to retrieve, set the limit to 0 to retrieve all posts.
  ## All of the posts returned are fully ready for displaying and parsing (They are unescaped.)
  var sqlStatement = "SELECT * FROM posts WHERE sender = " & escape(sanitizeHandle(handle)) & ";"
  if limit != 0:
    var i = 0;
    for post in db.all(sqlStatement):
      inc(i)    
      if i > limit:
        break
      result.add(db.constructPostFromRow(post))
  else:
    for post in db.all(sqlStatement):
      result.add(db.constructPostFromRow(post))
  return result

proc getPostsByUserId*(db: DbConn, id:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts using the User's ID.
  ## This behaves exactly like the getPostsByUserHandle procedure.
  
  # This procedure will piggy-back off of getHandleFromId and getPostsByUserId.
  return db.getPostsByUserHandle(db.getHandleFromId(id),limit)

proc getTotalPosts*(db: DbConn): int =
  ## A procedure to get the total number of local posts.
  result = 0
  for x in db.all("SELECT local FROM posts;"):
    inc(result)
  return result

proc getLocalPosts*(db: DbConn, limit: int = 15): seq[Post] =
  ## A procedure to get posts from local users only.
  ## Set limit to 0 to disable the limit and get all posts from local users.
  let statement = db.stmt("SELECT * FROM posts WHERE local = true;")
  if limit != 0:
    for row in statement.all():
      if len(result) > limit:
        break
      result.add(db.constructPostFromRow(row))
  else:
    for row in statement.all():
      result.add(db.constructPostFromRow(row))
  statement.finalize()
  return result
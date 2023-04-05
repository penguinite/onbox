# Copyright © Leo Gavilieau 2022-2023
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# db/sqlite.nim:
## A database engine backend for sqlite3
## Currently, I am testing Pothole with this database backend only.

# From pothole
from ../conf import get, split, exists
import ../lib, ../user, ../post, ../crypto

# From standard library
import std/[db_sqlite, strutils, tables]

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
# For this module to work, both database schemas and user object definitions must be similar
const usersCols: OrderedTable[string,string] = {"id":"BLOB PRIMARY KEY UNIQUE NOT NULL", # The user ID
"handle":"VARCHAR(65535) UNIQUE NOT NULL", # The user's actual username (Fx. alice@alice.wonderland)
"name":"VARCHAR(65535)", # The user's display name (Fx. Alice)
"local":"BOOLEAN NOT NULL", # A boolean indicating whether the user originates from the local server or another one.
"email":"VARCHAR(225)", # The user's email (Empty for remote users)
"bio":"VARCHAR(65535)", # The user's biography 
"password":"VARCHAR(65535)", # The user's hashed & salted password (Empty for remote users obv)
"salt":"VARCHAR(65535)", # The user's salt (Empty for remote users obv)
"admin":"BOOLEAN NOT NULL", # A boolean indicating whether or not this is user is an Admin.
"is_frozen":"BOOLEAN NOT NULL"}.toOrderedTable # A boolean indicating whether this user is frozen (Posts from this user will not be stored)

const postsCols: OrderedTable[string, string] = {"id":"BLOB PRIMARY KEY UNIQUE NOT NULL", # The post Id
"recipients":"VARCHAR(65535)", # A comma-separated list of recipients since sqlite3 does not support arrays by default
"sender":"VARCHAR(65535) NOT NULL", # A string containing the sender handle
"written":"TIMESTAMP NOT NULL", # A timestamp containing the date that the post was written (and published)
"updated":"TIMESTAMP", # An optional timestamp containing the date that the post was updated
"local": "BOOLEAN NOT NULL"}.toOrderedTable # A boolean indicating whether the post originated from this server or other servers.

#! Some parts of this codebase depend on conf, post and user.
# TODO: Make sqlite Independent Again!

{.cast(gcsafe).}:
  var db:DbConn; 

proc init*(file: string = conf.get("db","filename"), noSchemaCheck:bool = false): bool =
  ## This procedure initializes a database using values from the config file.
    
  var dbfilename = conf.get("db","filename")
  debug "Opening database at " & dbfilename, "db/sqlite.init"
  db = open(dbfilename,"","","")
  
  # Let's create both tables by looping over the postCols and userCols tables
  var sqlStatement = "CREATE TABLE IF NOT EXISTS users (";
  for key, value in usersCols.pairs:
    sqlStatement.add(key & " " & value & ",")
  sqlStatement = sqlStatement[0 .. ^2]
  sqlStatement.add(");")

  if not db.tryExec(sql(sqlStatement)):
    error "Failed to create users table!", "db/sqlite.init"

  # Now posts table
  sqlStatement = "CREATE TABLE IF NOT EXISTS posts (";
  for key, value in postsCols.pairs:
    sqlStatement.add(key & " " & value & ",")
  sqlStatement = sqlStatement[0 .. ^2]
  sqlStatement.add(");")

  if not db.tryExec(sql(sqlStatement)):
    error "Failed to create posts table!", "db/sqlite.init"

  if noSchemaCheck:
    debug "Schema check skipped...","db/sqlite.init"
    echo "Database is done initializing!"
    return true # Return early since all thats left is the schema check

  # At this stage we will check individual columns and if they exist
  # So that we can individually update the database as we change stuff
  
  # I think getAllRows() returns a random order so we won't look 
  # at the order that these come in.
  var cols: seq[string] = @[]
  for row in db.getAllRows(sql"PRAGMA table_info('users');"):
    cols.add(row[1])

  var missing: seq[string] = @[]
  for key in usersCols.keys:
    if key in cols:
      continue
    else:
      missing.add(key)
  
  if len(missing) > 0:
    debug "Major difference between built-in schema and currently-used schema\nDid you forget to migrate?", "db/sqlite.init"
    error "Missing columns from users schema:\n" & $missing, "db/sqlite.init"
  
  cols = @[]
  for row in db.getAllRows(sql"PRAGMA table_info('posts');"):
    cols.add(row[1])

  missing = @[]
  for key in postsCols.keys:
    if key in cols:
      continue
    else:
      missing.add(key)
  
  if len(missing) > 0:
    debug "Major difference between built-in schema and currently-used schema\nDid you forget to migrate?", "db/sqlite.init"
    error "Missing columns from posts schema:\n" & $missing, "db/sqlite.init"

  echo "Database is done initializing!"

proc uninit*(): bool =
  ## Uninitialize the database.
  ## Or close it basically...
  try:
    db.close()  
    return true
  except:
    return false

proc addUser*(olduser: User): User =
  ## This takes a User object and puts it in the database
  var user = olduser.escape()[]

  # Check if handle already exists in the database
  var safeHandle = escape(safeifyHandle(toLowerAscii(olduser.handle)))
  if db.getRow(sql"SELECT handle FROM users WHERE handle = ?;", safeHandle) == @[safeHandle]:
    debug "User with handle " & olduser.handle & " already exists!","sqlite.addUser"
    return # Simply exit

  #A simple loop for checking if the Id exists
  # I am not exactly sure if this works but I see no reason why not.
  while (true):
    if db.getRow(sql"SELECT local FROM users WHERE id = ?;", user.id) == @[""]:
      break
    else:
      # User still exists! Generate new id!
      user.id = randomString()
      continue

  # We will loop over the fields of the User object and build
  # the SQL statement little by little.
  var sqlStatement = "INSERT OR REPLACE INTO users ("
  
  for key, value in user.fieldPairs:
    sqlStatement.add(key & ",")
  
  sqlStatement = sqlStatement[0 .. ^2]

  for key, value in user.fieldPairs:
    when typeof(value) is string:
      sqlStatement.add(value)
    when typeof(value) is bool:
      sqlStatement.add($value)
  
    sqlStatement.add(",")
  
  sqlStatement.add(");")

  if not db.tryExec(db.prepare(sqlStatement)):
    debug "Tried to insert user " & $user, "sqlite.addUser(beforeError)"
    debug "sqlStatement: " & sqlStatement, "sqlite.addUser(beforeError)"
    error "Failed to insert user!", "sqlite.addUser"

  new(result); result[] = user
  return result

proc getAdmins*(limit: int = 10): seq[string] = 
  ## A procedure that returns the usernames of all administrators.
  var sqlStatement = "SELECT handle FROM users WHERE admin = true;"
  for row in db.getAllRows(sql(sqlStatement)):
    result.add(row[0])
  return result
  
proc getTotalUsers*(): int =
  ## A procedure to get the total number of local users.
  var sqlStatement = "SELECT handle FROM users WHERE local = true;"
  result = 0
  for x in db.getAllRows(sql(sqlStatement)):
    inc(result)
  return result

proc getTotalPosts*(): int =
  ## A procedure to get the total number of local posts.
  var sqlStatement = "SELECT local FROM posts WHERE local = true;"
  result = 0
  for x in db.getAllRows(sql(sqlStatement)):
    inc(result)
  return result

#! Everything below this line was imported as-is from the old db.nim before db.nim was erased forever
# TODO: Optimize the below code.

func constructUserFromRow*(row: Row): User =
  ## This procedure takes a database row turns it into an 
  ## actual User object that can be returned and processed.
  ## getUserById() and getUserByHandle() both use this function to convert a database row to a user.
  ## 
  ## In most cases, you should not bother using this but the function is available for you to use
  ## (fx. when doing database operations directly yourself)
  ## If you are going to use this then make sure to include a compile-time check for users who do not use sqlite.
  var user = User()[] # Dereference early on for readability
  var i: int = -1;

  for key,value in user.fieldPairs:
    inc(i)
    # If its string, add it surrounding quotes
    # Otherwise add it whole
    when user.get(key) is bool:
      user.get(key) = parseBool(row[i])
    when user.get(key) is string:
      user.get(key) = row[i]

  new(result); result[] = user # Re-reference it at the end.
  return result.unescape()

proc userIdExists*(id:string): bool =
  ## A procedure to check if a user exists by id
  var row = db.getRow(sql"SELECT id FROM users WHERE id = ?;", id)
  if row == @[""]:
    return false # User does not exist
  return true # User exists

proc userHandleExists*(handle:string): bool =
  ## A procedure to check if a user exists by handle
  var row = db.getRow(sql"SELECT handle FROM users WHERE handle = ?;", escape(safeifyHandle(toLowerAscii(handle))))
  if row == @[""]:
    return false # User does not exist
  return true # User exists

proc getUserById*(id: string): User =
  ## Retrieve a user from the database using their id
  if not userIdExists(id):
    debug("Something tried to access a non-existent user with id: " & id, "db.getUserById")
    return
  var row = db.getRow(sql"SELECT * FROM users WHERE id = ?;", id)
  return constructUserFromRow(row)

proc getUserByHandle*(handle: string): User =
  ## Retrieve a user from the database using their handle
  if not userHandleExists(handle):
    debug("Something tried to access a non-existent user with the handle: " & handle, "db.getUserById")
    return
  var row = db.getRow(sql"SELECT * FROM users WHERE handle = ?;", escape(safeifyHandle(toLowerAscii(handle))))
  return constructUserFromRow(row)

proc update(table, condition, column, value: string, ): bool =
  ## A procedure to update any value, in any column in any table.
  ## This procedure should be wrapped, you can use updateUserByHandle() or
  ## updateUserById() instead of using this directly.
  var sqlStatement = db.prepare("UPDATE " & table & " SET " & column & " = " & escape(value,"","") & " WHERE " & condition & ";")
  return db.tryExec(sqlStatement)

proc updateUserByHandle*(handle, column, value: string): bool =
  ## A procedure to update the user by their handle
  # Check that the user handle exists
  if not userHandleExists(handle):
    return false

  # Check if it's a valid column to update
  if not usersCols.hasKey(column):
    return false
  
  # Then update!
  return update("users","handle = " & escape(safeifyHandle(toLowerAscii(handle))),column,value)

proc updateUserById*(id, column, value: string): bool = 
  ## A procedure to update the user by their ID
  # Check that the user id exists
  if not userIdExists(id):
    return false

  # Check if it's a valid column to update
  if not usersCols.hasKey(column):
    return false

  # Then update!
  return update("users","id = " & id,column, value)

proc getIdFromHandle*(handle: string): string =
  ## A function to convert a handle to an id.
  if not userHandleExists(handle):
    return ""
  var row = db.getRow(sql"SELECT id FROM users WHERE handle = ?;", escape(safeifyHandle(toLowerAscii(handle))))
  return unescape(row[0])

proc getHandleFromId*(id: string): string =
  ## A function to convert an id to a handle.
  if not userIdExists(id):
    return ""
  var row = db.getRow(sql"SELECT handle FROM users WHERE id = ?;", id)
  return unescape(row[0])

proc addPost*(post: Post): Post =
  ## A function add a post into the database
  ## This will be escaped by post.escape()
  
  #[
    Note: in other parts of the code, I have
    avoided the dereferencing call since it looks ugly.
    But since we will be parsing lots of posts, I say we keep this unchanged.
    We need the memory for other things such as Potcode parsing.
    And this section is not that ugly anyways.
  ]#
  var newpost: Post = post.escape()

  # Someone has tried to add a post twice. We just won't add it.
  if db.getRow(sql"SELECT local FROM posts WHERE id = ?;", newpost.id) != @[""]:
    return
      
  debug("Inserting user with Id " & newpost.id & "", "db.addPost")

  # Let's loop over the newuser field pairs and
  # Build the SQL statement as we go.
  var sqlStatement = "INSERT OR REPLACE INTO posts ("

  var i = 0;
  for key, value in newpost[].fieldPairs:
    inc(i)
    sqlStatement.add(key & ",")
  
  # Remove last character
  sqlStatement = sqlStatement[0 .. ^2]

  # Add the missing part
  sqlStatement.add(") VALUES (")

  # The other part of the SQL statement
  # The values.
  i = 0;
  for key, value in newpost[].fieldPairs:
    inc(i)
    # If its string, add it surrounding quotes
    # Otherwise add it whole
    when newpost[].get(key) is string:
      sqlStatement.add(value)
    
    when newpost[].get(key) is seq[string]:
      sqlStatement.add("\"")
      sqlStatement.add(value.join(","))
      sqlStatement.add("\"")
    
    when newpost[].get(key) is bool:
      sqlStatement.add($value)
    
    sqlStatement.add(",")

  # Remove last character again...
  sqlStatement = sqlStatement[0 .. ^2]

  # Add the other missing part
  sqlStatement.add(");")

  echo(sqlStatement)
  if not db.tryExec(db.prepare(sqlStatement)):
    debug("Tried to insert post: " & $newpost, "db.addPost(beforeError)")
    error("tryExec returns error!", "db.addPost")

  return newpost

proc postIdExists*(id: string): bool =
  ## A function to see if a post id exists in the database
  var row = db.getRow(sql"SELECT id FROM posts WHERE id = ?;", id)
  if row == @[""]:
    return false
  else:
    return true

proc updatePostById*(id, column, value: string): bool =
  ## A procedure to update a post using it's id
  return update("posts","id = " & id, column, value)

proc constructPostFromRow*(row: Row): Post =
  ## A procedure that takes a database Row (From the Posts table)
  ## And turns it into a Post object ready for display, parsing and so on.
  var post = Post()[]

  # This looks ugly, I know, I had to wrap it with
  # two specific functions but we don't have to re-write this
  # even if we add new things to the User object. EXCEPT!
  # if we introduce new data types to the User object
  var i: int = 0;

  for key,value in post.fieldPairs:
    inc(i)
    # If its string, add it surrounding quotes
    # Otherwise add it whole
    when post.get(key) is bool:
      post.get(key) = parseBool(row[i - 1])
    when post.get(key) is string:
      post.get(key) = row[i - 1]
    when post.get(key) is seq[string]:
      post.get(key) = row[i - 1].split(",")

  new(result); result[] = post
  return result.unescape()

proc getPostById*(id: string): Post =
  ## A procedure to get a post object from the db using its id
  if not postIdExists(id):
    debug("Someone tried to request a non-existent post. Id: " & id, "db.getPostById")
    return ## Not sure what to do
  var row = db.getRow(sql"SELECT * FROM posts WHERE id = ?;", id)
  return constructPostFromRow(row)

proc getPostsByUserHandle*(handle:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts from the db using the users handle
  if not userHandleExists(handle):
    return 

  var sqlStatement = db.prepare("SELECT * FROM posts WHERE sender = " & escape(safeifyHandle(toLowerAscii(handle))) & ";")

  for row in db.fastRows(sqlStatement):
    if limit != 0:
      if len(result) > limit:
        break
    result.add(row.constructPostFromRow())

proc getPostsByUserId*(id:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts from the db using the users id
  if not userIdExists(id):
    return

  var sqlStatement = db.prepare("SELECT * FROM posts WHERE sender = " & escape(getHandleFromId(id)))

  for row in db.fastRows(sqlStatement):
    if limit != 0:
      if len(result) > limit:
        break
    result.add(row.constructPostFromRow)
  

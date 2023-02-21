# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later.
#
# db/sqlite.nim:
## A database engine backend for sqlite3
## Currently, I am testing Pothole with this database backend only.


# From pothole
import ../conf,../lib,../user,../crypto,../post

# From standard library
import std/[db_sqlite, strutils, tables]

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
# For this module to work, both database schemas and user object definitions must be similar
const usersCols: Table[string,string] = {"id":"BLOB PRIMARY KEY UNIQUE NOT NULL", # The user ID
"handle":"VARCHAR(65535) UNIQUE NOT NULL", # The user's actual username (Fx. alice@alice.wonderland)
"name":"VARCHAR(65535)", # The user's display name (Fx. Alice)
"local":"BOOLEAN NOT NULL", # A boolean indicating whether the user originates from the local server or another one.
"email":"VARCHAR(225)", # The user's email (Empty for remote users)
"bio":"VARCHAR(65535)", # The user's biography 
"password":"VARCHAR(65535)", # The user's hashed & salted password (Empty for remote users obv)
"salt":"VARCHAR(65535)", # The user's salt (Empty for remote users obv)
"admin":"BOOLEAN NOT NULL", # A boolean indicating whether or not this is user is an Admin.
"is_frozen":"BOOLEAN NOT NULL"}.toTable # A boolean indicating whether this user is frozen (Posts from this user will not be stored)

const postsCols: Table[string, string] = {"id":"BLOB PRIMARY KEY UNIQUE NOT NULL", # The post Id
"contexts":"VARCHAR(65535)", # What JSON-LD contexts the post uses
"recipients":"VARCHAR(65535)", # A comma-separated list of recipients since sqlite3 does not support arrays by default
"sender":"VARCHAR(65535) NOT NULL", # A string containing the sender handle
"written":"TIMESTAMP NOT NULL", # A timestamp containing the date that the post was written (and published)
"updated":"TIMESTAMP", # An optional timestamp containing the date that the post was updated
"local": "BOOLEAN NOT NULL"}.toTable # A boolean indicating whether the post originated from this server or other servers.

{.gcsafe.}:
  var db:DbConn; 

proc init*(): bool =
  ## This procedure initializes a database using values from the config file.
  if not exists("db","filename"):
    error "Config file is missing essential option for sqlite db engine; db:filename","db/sqlite.init"
    
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

  # At this stage we will check individual columns and if they exist
  # So that we can individually update the database as we change stuff
  # The first row looks like this: @["0", "id", "BLOB", "1", "", "1"]
  var missingCols: seq[string] = @[];
  var i = -1;
  for row in db.getAllRows(sql"PRAGMA table_info('posts');"):
    echo row


  echo "Database is done initializing!"

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
  
proc getTotalUsers*(): int =
  ## A procedure to get the total number of local users.
  var sqlStatement = "SELECT handle FROM users WHERE local = true;"

proc getTotalPosts*(): int =
  ## A procedure to get the total number of local posts.
  var sqlStatement = "SELECT local FROM posts WHERE local = true;"



#! Everything below this line was imported as-is from db.nim before db.nim was erased forever
# TODO: Optimize the below code.

func constructUserFromRow*(row: Row): User =
  ## This procedure takes a database row (from either getUserById() or getUserByHandle())
  ## and turns it into an actual User object that can be returned and processed.
  var user = User()

  # This looks ugly, I know, I had to wrap it with
  # two specific functions but we don't have to re-write this
  # even if we add new things to the User object. EXCEPT!
  # if we introduce new data types to the User object
  var i: int = 0;

  for key,value in user[].fieldPairs:
    inc(i)
    # If its string, add it surrounding quotes
    # Otherwise add it whole
    when user[].get(key) is bool:
      user[].get(key) = parseBool(row[i - 1])
    when user[].get(key) is string:
      user[].get(key) = row[i - 1]

  return user.unescape()

proc userIdExists*(id:string): bool =
  ## A procedure to check if a user exists by id
  var row = db.getRow(sql"SELECT id FROM users WHERE id = ?;", id)
  if row == @[""]:
    return false
  else:
    return true

proc userHandleExists*(handle:string): bool =
  ## A procedure to check if a user exists by handle
  var row = db.getRow(sql"SELECT handle FROM users WHERE handle = ?;", escape(safeifyHandle(toLowerAscii(handle))))
  if row == @[""]:
    return false
  else:
    return true

proc getUserById*(id: string): User =
  ## Retrieve a user from the database using their id
  if not userIdExists(id):
    debug("Someone tried to access a non-existent user with id: " & id, "db.getUserById")
    return
  var row = db.getRow(sql"SELECT * FROM users WHERE id = ?;", id)
  return constructUserFromRow(row)

proc getUserByHandle*(handle: string): User =
  ## Retrieve a user from the database using their handle
  if not userHandleExists(handle):
    debug("Someone tried to access a non-existent user with the handle: " & handle, "db.getUserById")
    return
  var row = db.getRow(sql"SELECT * FROM users WHERE handle = ?;", escape(safeifyHandle(toLowerAscii(handle))))
  return constructUserFromRow(row)

proc update*(table, condition, column, value: string, ): bool =
  ## A procedure to update any value, in any column in any table.
  ## This procedure should be wrapped, you can use updateUserByHandle() or
  ## updateUserById() instead of using this directly.
  var sqlStatement = db.prepare("UPDATE " & table & " SET " & column & " = " & escape(value,"","") & " WHERE " & condition & ";")
  return db.tryExec(sqlStatement)

proc updateUserByHandle*(handle, column, value: string): bool =
  ## A procedure to update the user by their handle
  var handle2 = escape(safeifyHandle(toLowerAscii(handle)))
  return update("users","handle = " & handle2,column,value)

proc updateUserById*(id, column, value: string): bool = 
  ## A procedure to update the user by their ID
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
  var post = Post()

  # This looks ugly, I know, I had to wrap it with
  # two specific functions but we don't have to re-write this
  # even if we add new things to the User object. EXCEPT!
  # if we introduce new data types to the User object
  var i: int = 0;

  for key,value in post[].fieldPairs:
    inc(i)
    # If its string, add it surrounding quotes
    # Otherwise add it whole
    when post[].get(key) is bool:
      post[].get(key) = parseBool(row[i - 1])

    when post[].get(key) is string:
      post[].get(key) = row[i - 1]

    when post[].get(key) is seq[string]:
      post[].get(key) = row[i - 1].split(",")

  return post.unescape()

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

  result = @[] # Clear this... It's already cleared but I wanna make sure...
  for row in db.fastRows(sqlStatement):
    if limit != 0:
      if len(result) > limit:
        break
    result.add(row.constructPostFromRow())
  
  return result  

proc getPostsByUserId*(id:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts from the db using the users id
  return getPostsByUserHandle(getHandleFromId(id),limit)
  

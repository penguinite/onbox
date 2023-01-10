# Copyright © Louie Quartz 2022-2023
# Licensed under the AGPL version 3 or later.
#
# db.nim  ;;  Database functions

# From pothole
import lib
import conf
import data
import crypto

# From standard library
import std/[db_sqlite,strutils]

{.gcsafe.}:
  var db*:DbConn;

proc init*(dbtype: string = get("database","type")): int {.discardable.} =
  ## This procedure initializes the database. All on its own!
  ## It uses configuration values from conf to do everything by itself
  var dbtype2 = toLower(dbtype)

  # Mostly for future-proofing
  case dbtype2:
  of "sqlite":
    # Here we try to open the database
    if exists("database","filename") == false:
      error("No database filename provided","db.init.sqlite")
    debug("Opening sqlite database at " & get("database","filename"),"db.init.sqlite")
    db = open(get("database","filename"),"","","")
  else:
    error("Unknown database type (" & dbtype & ")","db.init")

  # Initializes the globally shared database connection
  debug "Initializing database...","db.init"
  debug "Creating user's table","db.init"

  # Create users table
  if not db.tryExec(sql("CREATE TABLE IF NOT EXISTS users (id BLOB PRIMARY KEY UNIQUE NOT NULL,handle VARCHAR(65535) UNIQUE NOT NULL,name VARCHAR(65535) NOT NULL,local BOOLEAN NOT NULL, email VARCHAR(255),bio VARCHAR(65535),password VARCHAR(65535), salt VARCHAR(65535), is_frozen BOOLEAN);")):
    # Database failed to initialize
    error("Couldn't initialize database! Creating users table failed!","db.init.actualinit")

  debug "Creating posts/activities table","db.init"

  # Create posts table
  if not db.tryExec(sql("CREATE TABLE IF NOT EXISTS posts ( id BLOB PRIMARY KEY UNIQUE NOT NULL, recipients VARCHAR(65535), sender VARCHAR(65535) NOT NULL, replyto VARCHAR(65535), content VARCHAR(65535), written TIMESTAMP NOT NULL, updated TIMESTAMP, local BOOLEAN NOT NULL );")):
    error("Couldn't initialize database! Creating posts table failed!","db.init.actualinit")

  echo("Database is done initializing!")

  return 0;


# This is over-engineered but it will allow us to define 
# the User data type however we want in the future without
# having to change a lot
proc addUser*(user: User): User =
  ## This takes a User object and puts it in the database  
  var newuser: User = user.escape();
  
  # Check if user exists first.
  var handleRow = db.getRow(sql"SELECT * FROM users WHERE handle = ?;", newuser.handle)

  # Check if the handle exists already, if it does then return false and don't proceed.
  if handleRow[0] == newuser.handle:
    debug("User with handle " & newuser.handle & " already exists!", "db.addUser")

  # A simple loop for checking if the Id exists
  # I am not exactly sure if this works but I see no reason why not.
  while (true):
    if db.getRow(sql"SELECT local FROM users WHERE id = ?;", newuser.id) == @[""]:
      break
    else:
      # User still exists! Generate new id!
      newuser.id = randomString()
      continue
      
  
  debug("Inserting user with Id " & newuser.id & " and handle " & newuser.handle, "db.addUser")

  # Let's loop over the newuser field pairs and
  # Build the SQL statement as we go.
  var sqlStatement = "INSERT OR REPLACE INTO users ("

  var i = 0;
  for key, value in newuser[].fieldPairs:
    inc(i)
    sqlStatement.add(key & ",")
  
  # Remove last character
  sqlStatement = sqlStatement[0 .. ^2]

  # Add the missing part
  sqlStatement.add(") VALUES (")

  # The other part of the SQL statement
  # The values.
  i = 0;
  for key, value in newuser[].fieldPairs:
    inc(i)
    # If its string, add it surrounding quotes
    # Otherwise add it whole
    when newuser[].get(key) is string:
      sqlStatement.add(value)
    else:  
      sqlStatement.add($value)
    
    sqlStatement.add(",")

  # Remove last character again...
  sqlStatement = sqlStatement[0 .. ^2]

  # Add the other missing part
  sqlStatement.add(");")
  if not db.tryExec(db.prepare(sqlStatement)):
    debug("Tried to insert user " & $newuser, "db.addUser(beforeError)")
    error("tryExec returns error!", "db.addUser")

  return newuser

proc constructUserFromRow*(row: Row): User =
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

proc getUserById*(id: string): User =
  ## Retrieve a user from the database using their id
  var row = db.getRow(sql"SELECT * FROM users WHERE id = ?;", id)
  return constructUserFromRow(row)

proc getUserByHandle*(handle: string): User =
  ## Retrieve a user from the database using their handle
  var row = db.getRow(sql"SELECT * FROM users WHERE handle = ?;", handle)
  return constructUserFromRow(row)

proc updateUser*(table, condition, column, value: string, ): bool =
  ## A procedure to update any value, in any column in any table.
  ## This procedure should be wrapped, you can use updateUserByHandle() or
  ## updateUserById() instead of using this directly.
  try:
    db.exec(sql"UPDATE ? SET ? = ? WHERE ? ", table, column, escape(value,"",""), condition)
    return true
  except:
    return false

proc updateUserByHandle*(handle, column, value: string): bool =
  ## A procedure to update the user by their handle
  try:
    var handle2 = escape(safeifyHandle(toLowerAscii(handle)))
    updateUser("users","handle = " & handle2,column,value)
  except:
    return false

proc updateUserById*(id, column, value: string): bool = 
  ## A procedure to update the user by their ID
  try:
    return updateUser("users","id = " & id,column, value)
  except:
    return false

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


proc addPost*(post: Post): bool =
  var newpost: Post = post.escape()
  # TODO: Implement this...
  return true

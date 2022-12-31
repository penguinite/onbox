# Copyright © Louie Quartz 2022
# Licensed under the AGPL version 3 or later.
#
# db.nim  ;;  Database functions

# From pothole
import lib
import conf
import data

# From standard library
import std/[db_sqlite,strutils]

{.gcsafe.}:
  var db*:DbConn;

proc init*(dbtype: string = get("database","type")) =
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
  if not db.tryExec(sql("CREATE TABLE IF NOT EXISTS users (id BLOB PRIMARY KEY,handle VARCHAR(65535) UNIQUE NOT NULL,name VARCHAR(65535) NOT NULL,local BOOLEAN NOT NULL, email VARCHAR(255),bio VARCHAR(65535),password VARCHAR(65535), salt VARCHAR(65535), is_frozen BOOLEAN);")):
    # Database failed to initialize
    error("Couldn't initialize database! Creating users table failed!","db.init.actualinit")

  debug "Creating posts/activities table","db.init"

  # Create posts table
  if not db.tryExec(sql("CREATE TABLE IF NOT EXISTS posts (id BLOB PRIMARY KEY,sender VARCHAR(65535) NOT NULL,written TIMESTAMP NOT NULL,updated TIMESTAMP,recipients VARCHAR(65535),post VARCHAR(65535) NOT NULL);")):
    error("Couldn't initialize database! Creating posts table failed!","db.init.actualinit")


# This is over-engineered but it will allow us to define 
# the User data type however we want in the future without
# having to change a lot
proc addUser*(user: User): bool =
  ## This takes a User object and puts it in the database
  var newuser: User = user.escape();
  #debug("Inserting user " & $newuser, "db.addUser")
  
  # Let's loop over the newuser field pairs and
  # Build the SQL statement as we go.
  var sqlStatement = "INSERT OR REPLACE INTO users ("

  var i = 0;
  for key, value in newuser.fieldPairs:
    inc(i)
    sqlStatement.add(key & ",")
  
  # Remove last character
  sqlStatement = sqlStatement[0 .. ^2]

  # Add the missing part
  sqlStatement.add(") VALUES (")

  # The other part of the SQL statement
  # The values.
  i = 0;
  for key, value in newuser.fieldPairs:
    inc(i)
    # If its string, add it surrounding quotes
    # Otherwise add it whole
    if key is string:
      sqlStatement.add("\"" & $value & "\"")
    else:  
      sqlStatement.add($value)
    
    sqlStatement.add(",")

  # Remove last character again...
  sqlStatement = sqlStatement[0 .. ^2]

  # Add the other missing part
  sqlStatement.add(");")

  return db.tryExec(db.prepare(sqlStatement))

proc constructUserFromRow*(row: Row): User =
  ## This procedure takes a database row (from either getUserById() or getUserByHandle())
  ## and turns it into an actual User object that can be returned and processed.
  var user: User;

  # This looks ugly, I know, I had to wrap it with
  # two specific functions but we don't have to re-write this
  # even if we add new things to the User object. EXCEPT!
  # if we introduce new data types to the User object
  var i: int = 0;

  for key,value in user.fieldPairs:
      inc(i)
      # If its string, add it surrounding quotes
      # Otherwise add it whole
      when user.get(key) is bool:
        user.get(key) = parseBool(row[i - 1])
      when user.get(key) is string:
        user.get(key) = convertIfNeccessary(row[i - 1])

  return user.unescape()

proc getUserById*(id: string): User =
  ## Retrieve a user from the database using their id
  var row = db.getRow(sql"SELECT * FROM users WHERE id = ?;", id)
  return constructUserFromRow(row)

proc getUserByHandle*(handle: string): User =
  ## Retrieve a user from the database using their handle
  var row = db.getRow(sql"SELECT * FROM users WHERE handle = ?;", handle)
  return constructUserFromRow(row)

proc update*(table, condition, column, value: string, ): bool =
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
    var handle2 = escape(safeifyHandle(toLowerAscii(handle)),"","")
    update("users","handle = " & handle2,column,value)
  except:
    return false

proc updateUserById*(id, column, value: string): bool = 
  ## A procedure to update the user by their ID
  try:
    return update("users","id = " & id,column, value)
  except:
    return false

proc getIdFromHandle*(handle: string): string =
  ## A function to convert a handle to an id.
  return getUserByHandle(handle).id

proc getHandleFromId*(id: string): string =
  ## A function to convert an id to a handle.
  return getUserById(id).handle

proc userIdExists*(id:string): bool =
  var row = db.getRow(sql"SELECT * FROM users WHERE id = ?;", id)
  var hit: int = 0;
  var i: int = 0;
  for x in row:
    inc(i)
    if x == "":
      inc(hit)
  if hit == i:
    return false;
  else:
    return true

proc userHandleExists*(handle:string): bool =
  var row = db.getRow(sql"SELECT * FROM users WHERE handle = ?;", handle)
  var hit: int = 0;
  var i: int = 0;
  for x in row:
    inc(i)
    if x == "":
      inc(hit)
  if hit == i:
    return false;
  else:
    return true
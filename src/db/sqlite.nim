# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later.
#
# db/sqlite.nim:
## A database engine backend for sqlite3
## Note, that this "backend" uses db_sqlite but it's purpose is also to produce sqlite3 compatible queries

# From pothole
import ../conf,../lib,../user,../crypto

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
    error "Config file is missing essential option for sqlite db engine; db:filename","sqlite.init"
    
  var dbfilename = conf.get("db","filename")
  debug "Opening database at " & dbfilename, "sqlite.init"
  db = open(dbfilename,"","","")
  
  # Let's create both tables by looping over the postCols and userCols tables
  var sqlStatement = "CREATE TABLE IF NOT EXISTS users (";
  for key, value in usersCols:
    

  # At this stage we will check individual columns and if they exist

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

func constructUserFromRow*(row: Row): User =
  ## This procedure takes a Riow
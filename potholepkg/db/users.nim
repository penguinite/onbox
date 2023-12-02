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
# db/sqlite/users.nim:
## This module contains all database logic for handling users.

# From somewhere in Pothole
import ../[user, lib]

# From somewhere in the standard library
import std/strutils except isEmptyOrWhitespace
import std/[tables, options]

# From somewhere else (nimble etc.)
when (NimMajor, NimMinor, NimPatch) >= (1, 7, 3):
  include db_connector/db_postgres
else:
  include db_postgres

import common

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
# For this module to work, both database schemas and user object definitions must be similar
const usersCols*: OrderedTable[string,string] = {"id":"BLOB PRIMARY KEY UNIQUE NOT NULL", # The user ID
"kind":"VARCHAR(65535) NOT NULL", # The user type, see UserType object in user.nim
"handle":"VARCHAR(65535) UNIQUE NOT NULL", # The user's actual username (Fx. alice@alice.wonderland)
"name":"VARCHAR(65535)", # The user's display name (Fx. Alice)
"local":"BOOLEAN NOT NULL", # A boolean indicating whether the user originates from the local server or another one.
"email":"VARCHAR(225)", # The user's email (Empty for remote users)
"bio":"VARCHAR(65535)", # The user's biography 
"password":"VARCHAR(65535)", # The user's hashed & salted password (Empty for remote users obv)
"salt":"VARCHAR(65535)", # The user's salt (Empty for remote users obv)
"kdf":"INTEGER NOT NULL", # The version of the key derivation function. See DESIGN.md's "Key derivation function table" for more.
"admin":"BOOLEAN NOT NULL", # A boolean indicating whether or not this is user is an Admin.
"is_frozen":"BOOLEAN NOT NULL", # A boolean indicating whether this user is frozen (Posts from this user will not be stored)
"is_approved":"BOOLEAN NOT NULL"}.toOrderedTable  # A boolean indicating if the user hs been approved by an administrator


proc addUser*(db: DbConn, user: User): bool = 
  ## Add a user to the database
  ## This procedure expects an escaped user to be handed to it.
  var testStmt = prepare(db, "checkForHandle", sql"SELECT local FROM users WHERE $1 = $2;", 2) 

  if has(db.getRow(testStmt, "handle", user.handle)):
    log "User with handle " & user.handle & " already exists!"
    return false # Simply exit

  if has(db.getRow(testStmt, "id", user.id)):
    log "User with id " & user.id & " already exists!"
    return false # Return false if id already exists
  
  # TODO: Likewise with the addPost() proc, there has to be a better way than this.
  # It's just too ugly.
  #[
  try:
    db.exec(
      db.prepare("insertUser", sql"INSERT OR REPLACE INTO users (id,kind,handle,name,local,email,bio,password,salt,kdf,admin,is_frozen,is_approved) VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)",12),
      user.id,
      user.kind,
      user.handle,
      user.name,
      user.local,
      user.email,
      user.bio,
      user.password,
      user.salt,
      user.kdf,
      user.admin,
      user.is_frozen,
      user.is_approved
    )
  except CatchableError as err:
    log "Failed to insert user: ", err.msg
  ]#

  return true

proc getAdmins*(db: DbConn): seq[string] = 
  ## A procedure that returns the usernames of all administrators.
  for row in db.getAllRows(sql"SELECT handle FROM users WHERE admin = true;"):
    result.add(row[0])
  return result
  
proc getTotalLocalUsers*(db: DbConn): int =
  ## A procedure to get the total number of local users.
  result = 0
  for x in db.getAllRows(sql"SELECT is_approved FROM users WHERE local = true;"):
    inc(result)
  return result

proc userIdExists*(db: DbConn, id:string): bool =
  ## A procedure to check if a user exists by id
  ## This procedures does escape IDs by default.
  return has(db.getRow(db.prepare("userIdExists",sql"SELECT local FROM users WHERE id = $1;",1),id))

proc userHandleExists*(db: DbConn, handle:string): bool =
  ## A procedure to check if a user exists by handle
  ## This procedure does sanitize and escape handles by default
  return has(db.getRow(db.prepare("userHandleExists",sql"SELECT local FROM users WHERE handle = $1;",1),handle))

proc constructUserFromRow*(row: Row): User =
  ## A procedure that takes a database Row (From the users table)
  ## And turns it into a User object, ready for processing.
  ## It unescapes users by default
  result = User()

  # This looks ugly, I know, I had to wrap it with
  # two specific functions but we don't have to re-write this
  # even if we add new things to the User object. EXCEPT!
  # if we introduce new data types to the User object
  var i: int = -1;

  for key,value in result.fieldPairs:
    inc(i)
    # If its string, add it surrounding quotes
    # Otherwise add it whole
    when result.get(key) is bool:
      result.get(key) = parseBool(row[i])
    when result.get(key) is string:
      result.get(key) = row[i]
    when result.get(key) is int:
      result.get(key) = parseInt(row[i])
    when result.get(key) is UserType:
      result.get(key) = toUserType(row[i])

  return result

proc getUserById*(db: DbConn, id: string): User =
  ## Retrieve a user from the database using their id
  ## This procedure returns a fully unescaped user, you do not need to do anything to it.
  ## This procedure expects a regular ID, it will sanitize and escape it by default.
  if not db.userIdExists(id):
    error "Something or someone tried to get a non-existent user with the id \"" & id & "\""

  return constructUserFromRow(db.getRow(sql"SELECT * FROM users WHERE id = ?;"))

proc getUserByHandle*(db: DbConn, handle: string): User =
  ## Retrieve a user from the database using their handle
  ## This procedure returns a fully unescaped user, you do not need to do anything to it.
  ## This procedure expects a regular handle, it will sanitize and escape it by default.
  if not db.userHandleExists(handle):
    error "Something or someone tried to get a non-existent user with the handle \"" & handle & "\""
    
  return constructUserFromRow(db.one("SELECT * FROM users WHERE handle = " & escape(sanitizeHandle(handle)) & ";").get)

proc updateUserByHandle*(db: DbConn, handle: User.handle, column, value: string): bool =
  ## A procedure to update any user (The user is identified by their handle)
  ## The *only* parameter that is sanitized is the handle, the value has to be sanitized by your user program!
  ## Or else you will be liable to truly awful security attacks!
  ## For guidance, look at the sanitizeHandle() procedure in user.nim or the escape() procedure in the strutils module
  if not db.userHandleExists(handle):
    return false

  # Check if it's a valid column to update
  if not usersCols.hasKey(column):
    return false
  
  # Then update!
  return db.update("users", "handle = " & escape(sanitizeHandle(handle)), column, value)
  
proc updateUserById*(db: DbConn, id: User.id, column, value: string): bool = 
  ## A procedure to update any user (The user is identified by their ID)
  ## Like with the updateUserByHandle() function, the only sanitized parameter is the id. 
  ## You *have* to sanitize the value argument yourself
  ## For guidance, look at the sanitizeHandle() procedure in user.nim or the escape() procedure in the strutils module
  if not db.userIdExists(id):
    return false

  # Check if it's a valid column to update
  if not usersCols.hasKey(column):
    return false

  return db.update("users", "id = " & escape(id), column, value)

proc getIdFromHandle*(db: DbConn, handle: string): string =
  ## A function to convert a user handle to an id.
  ## This procedure expects a regular handle, it will sanitize and escape it by default.
  if not db.userHandleExists(handle):
    error "Something or someone tried to get a non-existent user with the handle \"" & handle & "\""
  
  return unescape(db.one("SELECT id FROM users WHERE handle = " & escape(sanitizeHandle(handle)) & ";").get()[0].strVal,"","")

proc getHandleFromId*(db: DbConn, id: string): string =
  ## A function to convert a  id to a handle.
  ## This procedure expects a regular ID, it will sanitize and escape it by default.
  if not db.userIdExists(id):
    error "Something or someone tried to get a non-existent user with the id \"" & id & "\""
  
  return unescape(db.one("SELECT handle FROm users WHERE id = " & escape(id) & ";").get()[0].strVal,"","")
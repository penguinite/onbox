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

# From somewhere in Quark
import ../[user, strextra, crypto]
import ../private/[database, macros]

# From somewhere in the standard library
import std/[tables]

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
# For this module to work, both database schemas and user object definitions must be similar
const usersCols*: OrderedTable[string,string] = {"id":"TEXT PRIMARY KEY NOT NULL", # The user ID
"kind":"TEXT NOT NULL", # The user type, see UserType object in user.nim
"handle":"TEXT UNIQUE NOT NULL", # The user's actual username (Fx. alice@alice.wonderland)
"name":"TEXT DEFAULT 'New User'", # The user's display name (Fx. Alice)
"local":"BOOLEAN NOT NULL", # A boolean indicating whether the user originates from the local server or another one.
"email":"TEXT", # The user's email (Empty for remote users)
"bio":"TEXT", # The user's biography 
"password":"TEXT", # The user's hashed & salted password (Empty for remote users obv)
"salt":"TEXT", # The user's salt (Empty for remote users obv)
"kdf":"INTEGER NOT NULL", # The version of the key derivation function. See DESIGN.md's "Key derivation function table" for more.
"admin":"BOOLEAN NOT NULL DEFAULT FALSE", # A boolean indicating whether or not this user is an Admin.
"moderator":"BOOLEAN NOT NULL DEFAULT FALSE", # A boolean indicating whether or not this user is a Moderator.
"is_frozen":"BOOLEAN NOT NULL", # A boolean indicating whether this user is frozen (Posts from this user will not be stored)
"is_approved":"BOOLEAN NOT NULL"}.toOrderedTable  # A boolean indicating if the user hs been approved by an administrator


proc addUser*(db: DbConn, user: User) = 
  ## Add a user to the database
  ## This procedure expects an escaped user to be handed to it.
  var testStmt = sql"SELECT local FROM users WHERE ? = ?;"

  if has(db.getRow(testStmt, "handle", user.handle)): 
    raise newException(DbError, "User with same handle as \"" & user.handle & "\" already exists")

  if has(db.getRow(testStmt, "id", user.id)):
    raise newException(DbError, "User with same id as \"" & user.id & "\" already exists")
  
  # TODO: Likewise with the addPost() proc, there has to be a better way than this.
  # It's just too ugly.
  db.exec(
    sql"INSERT INTO users (id,kind,handle,name,local,email,bio,password,salt,kdf,admin,moderator,is_frozen,is_approved) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)",
    user.id,
    user.kind,
    user.handle,
    user.name,
    user.local,
    user.email,
    user.bio,
    user.password,
    user.salt,
    KDFToString(user.kdf),
    user.admin,
    user.moderator,
    user.is_frozen,
    user.is_approved
  )

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
  return has(db.getRow(sql"SELECT local FROM users WHERE id = ?;", id))

proc userHandleExists*(db: DbConn, handle:string): bool =
  ## A procedure to check if a user exists by handle
  ## This procedure does sanitize and escape handles by default
  return has(db.getRow(sql"SELECT local FROM users WHERE handle = ?;", sanitizeHandle(handle)))

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
    when result.get(key) is KDF:
      result.get(key) = StringToKDF(row[i])

  return result

proc getUserById*(db: DbConn, id: string): User =
  ## Retrieve a user from the database using their id
  ## This procedure returns a fully unescaped user, you do not need to do anything to it.
  ## This procedure expects a regular ID, it will sanitize and escape it by default.
  if not db.userIdExists(id):
    raise newException(DbError, "Couldn't find user with id \"" & id & "\"")

  return constructUserFromRow(db.getRow(sql"SELECT * FROM users WHERE id = ?;", id))

proc getUserByHandle*(db: DbConn, handle: string): User =
  ## Retrieve a user from the database using their handle
  ## This procedure returns a fully unescaped user, you do not need to do anything to it.
  ## This procedure expects a regular handle, it will sanitize and escape it by default.
  if not db.userHandleExists(handle):
    raise newException(DbError, "Couldn't find user with handle \"" & handle &  "\"")
    
  return constructUserFromRow(db.getRow(sql"SELECT * FROM users WHERE handle = ?;", sanitizeHandle(handle)))

proc updateUserByHandle*(db: DbConn, handle: string, column, value: string) =
  ## A procedure to update any user (The user is identified by their handle)
  ## The *only* parameter that is sanitized is the handle, the value has to be sanitized by your user program!
  ## Or else you will be liable to truly awful security attacks!
  ## For guidance, look at the sanitizeHandle() procedure in user.nim or the escape() procedure in the strutils module
  
  # Check if user exists or if the column exists.
  if not db.userHandleExists(handle):
    raise newException(DbError, "User with handle \"" & handle & "\" doesn't exist.")

  if not usersCols.hasKey(column):
    raise newException(DbError, "User table column \"" & column & "\" doesn't exist.")
  
  # Then update!
  db.exec(sql("UPDATE users SET " & column & " = ? WHERE handle = ?;"), value, sanitizeHandle(handle))
  
proc updateUserById*(db: DbConn, id: User.id, column, value: string) = 
  ## A procedure to update any user (The user is identified by their ID)
  ## Like with the updateUserByHandle() function, the only sanitized parameter is the id. 
  ## You *have* to sanitize the value argument yourself
  ## For guidance, look at the sanitizeHandle() procedure in user.nim or the escape() procedure in the strutils module
  
  # Check if the user or column exists
  if not db.userIdExists(id):
    raise newException(DbError, "User with id \"" & id & "\" doesn't exist.")
  
  if not usersCols.hasKey(column):
    raise newException(DbError, "User table column \"" & column & "\" doesn't exist.")

  # Then update!
  db.exec(sql("UPDATE users SET " & column & " = ? WHERE id = ?;"), value, id)

proc getIdFromHandle*(db: DbConn, handle: string): string =
  ## A function to convert a user handle to an id.
  ## This procedure expects a regular handle, it will sanitize and escape it by default.
  if not db.userHandleExists(handle):
    raise newException(DbError, "Couldn't find user with handle \"" & handle &  "\"")
  
  return db.getRow(sql"SELECT id FROM users WHERE handle = ?;", sanitizeHandle(handle))[0]

proc getHandleFromId*(db: DbConn, id: string): string =
  ## A function to convert a  id to a handle.
  ## This procedure expects a regular ID, it will sanitize and escape it by default.
  if not db.userIdExists(id):
    raise newException(DbError, "Couldn't find user with id \"" & id &  "\"")
  
  return db.getRow(sql"SELECT handle FROm users WHERE id = ?;", id)[0]

proc deleteUser*(db: DbConn, id: string) = 
  if not db.userIdExists(id):
    raise newException(DbError, "Couldn't find user with id \"" & id &  "\"")
  
  db.exec(sql"DELETE FROM users WHERE id = ?;", id)

proc deleteUsers*(db: DbConn, ids: seq[string]) = 
  for id in ids:
    db.deleteUser(id)
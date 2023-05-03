# Copyright © Leo Gavilieau 2023
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
## A database backend for sqlite3 (Using the tiny_sqlite module)
## This backend is very much early in development and it is actually untested

# TODO: Finish this.
# TODO TODO: Also only document the stuff thats different between this module and the postgres module. Nothing else.

# From somewhere in Pothole
import ../user, ../post, ../lib

# From somewhere in the standard library
import std/strutils except isEmptyOrWhitespace
import std/tables

# From somewhere else (nimble etc.)
import tiny_sqlite

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


# This is the database connection we will use.
# It's initialized at startup via the init() procedure defined here.
{.cast(gcsafe).}:
  var db:DbConn; 

proc init*(filename: string, noSchemaCheck:bool = false): bool =
  ## Do any initialization work.
  var caller = "db/sqlite.init" # Just so we dont repeat the same thing a whole lot.

  if filename.startsWith("__eat_flaming_death"):
    debug "Someone or something used the forbidden code", caller
    return false
  
  if isEmptyOrWhitespace(filename):
    debug "String is mostly empty or whitespace. ", caller
    return false

  debug "Opening database at " & filename, caller
  db = openDatabase(filename) 

  # Create tables by running through the postCols and userCols tables.
  var sqlStatement = "CREATE TABLE IF NOT EXISTS users ("
  for key, value in usersCols.pairs:
    sqlStatement.add(key & " " & value & ",")
  sqlStatement = sqlStatement[0 .. ^2]
  sqlStatement.add(");")

  try: # Try to run it and pray for good luck
    db.execScript(sqlStatement)
  except:
    error "Failed to create the users table!", caller

  # And now the posts table
  sqlStatement = "CREATE TABLE IF NOT EXISTS posts (";
  for key, value in postsCols.pairs:
    sqlStatement.add(key & " " & value & ",")
  sqlStatement = sqlStatement[0 .. ^2]
  sqlStatement.add(");")

  try: # Same as before
    db.execScript(sqlStatement)
  except:
    error "Failed to create the posts table!", caller
  
  # Now skip the schema check
  if noSchemaCheck:
    debug "Schema check skipped.", caller
    return true # All thats left is the schema check. So let's return early.

  var cols: seq[string] = @[]
  for row in db.all("PRAGMA table_info('users');"):
    cols.add(row[1].strVal)

  var missing: seq[string] = @[]
  for key in usersCols.keys:
    if key in cols:
      continue
    else:
      missing.add(key)
  
  if len(missing) > 0:
    debug "Major difference between built-in schema and currently-used schema", caller
    debug "Did you forget to migrate? Please migrate before re-running this program", caller
    error "Missing columns from users schema:\n" & $missing, caller

  # Now we do the same above schema check but for the posts table.

  cols = @[]
  for row in db.all("PRAGMA table_info('posts');"):
    cols.add(row[1].strVal)

  missing = @[]
  for key in postsCols.keys:
    if key in cols:
      continue
    else:
      missing.add(key)
  
  if len(missing) > 0:
    debug "Major difference between built-in schema and currently-used schema", caller
    debug "Did you forget to migrate? Please migrate before re-running this program", caller
    error "Missing columns from posts schema:\n" & $missing, caller

  return true

proc uninit*(): bool =
  ## Uninitialize the database.
  ## Or close it basically...
  db.close()

proc addUser*(user: User): User = 
  ## Add a user to the database
  # TODO: Look into using macros or templates to automatically generate this code.
  var sqlStatement = "INSERT INTO users("
  return user

proc userIdExists*(id:string): bool =
  ## A procedure to check if a user exists by id
  return false

proc userHandleExists*(handle:string): bool =
  ## A procedure to check if a user exists by handle
  return false

proc getUserById*(id: string): User =
  ## Retrieve a user from the database using their id
  return User()

proc getUserByHandle*(handle: string): User =
  ## Retrieve a user from the database using their handle
  return User()

proc updateUserByHandle*(handle, column, value: string): bool =
  ## A procedure to update the user by their handle
  return true

proc updateUserById*(id, column, value: string): bool = 
  ## A procedure to update the user by their ID
  return true

proc getIdFromHandle*(handle: string): string =
  ## A function to convert a user handle to an id.
  return ""

proc getHandleFromId*(id: string): string =
  ## A function to convert a  id to a handle.
  return ""

#! This comment marks the beginning of the Post section.
# Procedures here are primarily used for posts.

proc addPost*(post: Post): Post =
  ## A function add a post into the database
  return Post()

proc postIdExists*(id: string): bool =
  ## A function to see if a post id exists in the database
  return false

proc updatePostById*(id, column, value: string): bool =
  ## A procedure to update a post using it's id
  return true

proc getPostById*(id: string): Post =
  ## A procedure to get a post object from the db using its id
  return Post()

proc getPostsByUserHandle*(handle:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts from the db using the users handle
  return @[Post()]  

proc getPostsByUserId*(id:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts from the db using the users id
  return @[Post()]

proc getAdmins*(limit: int = 5): seq[string] =
  ## A procedure that returns the usernames of all administrators.
  return @[]

proc getTotalUsers*(): int =
  ## A procedure to get the total number of local users.
  return 0

proc getTotalPosts*(): int =
  ## A procedure to get the total number of local posts.
  return 0
  # TODO: Investigate why it does not work.
  var sqlStatement = "SELECT * FROM posts WHERE local = true;"

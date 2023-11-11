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
# db/sqlite.nim:
## A database backend for sqlite3 (Using the tiny_sqlite module)
## This backend is somewhat mature now.

# From somewhere in Pothole
import ../[user, post, lib, conf]

# From somewhere in the standard library
import std/strutils except isEmptyOrWhitespace
import std/tables

# From somewhere else (nimble etc.)
import tiny_sqlite

export DbConn, isOpen

proc has(db:DbConn,statement:string): bool =
  ## A quick helper function to check if a thing exists.
  try:
    if isNone(db.one(statement)):  
      return false
    return true
  except CatchableError as err:
    log "We are about to fatally crash so here is some information that might help debug this!"
    log "sqlStatement: ", statement
    error "tiny_sqlite returns error when using has() function: ", err.msg

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
# For this module to work, both database schemas and user object definitions must be similar
const usersCols: OrderedTable[string,string] = {"id":"BLOB PRIMARY KEY UNIQUE NOT NULL", # The user ID
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
"is_frozen":"BOOLEAN NOT NULL"}.toOrderedTable # A boolean indicating whether this user is frozen (Posts from this user will not be stored)

const postsCols: OrderedTable[string, string] = {"id":"BLOB PRIMARY KEY UNIQUE NOT NULL", # The post Id
"recipients":"VARCHAR(65535)", # A comma-separated list of recipients since sqlite3 does not support arrays by default
"sender":"VARCHAR(65535) NOT NULL", # A string containing the sender handle
"replyto": "VARCHAR(65535)", # A string containing the post that the sender is replying to, if at all.
"content": "VARCHAR(65535)", # A string containing the actual post's contents.
"written":"TIMESTAMP NOT NULL", # A timestamp containing the date that the post was written (and published)
"updated":"TIMESTAMP", # An optional timestamp containing the date that the post was updated
"modified":"BOOLEAN NOT NULL", # A boolean indicating whether the post was modified or not.
"local": "BOOLEAN NOT NULL", # A boolean indicating whether the post originated from this server or other servers.
"favorites": "VARCHAR(65535)", # A string containing a list of user ids that have reacted to this post alongside their reactions
"boosts": "VARCHAR(65535)", # A string containing a list of user ids that boosted this post.
"revisions": "VARCHAR(65535)", # A string containing previous revisions of a post
}.toOrderedTable 

proc createDbTableWithColsTable(db: DbConn, tablename: string, cols: OrderedTable[string,string]):  bool =
  ## We use this procedure to create a SQL statement that creates a table using the hard-coded rules
  # We build the sql statement slowly.
  var sqlStatement = "CREATE TABLE IF NOT EXISTS " & tablename & " ("
  for key, value in cols.pairs:
    sqlStatement.add("$# $#," % [key, value])
  sqlStatement = sqlStatement[0 .. ^2] # Remove last comma
  sqlStatement.add(");") # Add final two characters

  # Now we run and hope for the best!
  try:
    db.execScript(sqlStatement)
    return true
  except CatchableError as err:
    log "Error whilst creating table " & tablename & ": " & err.msg
    return false

proc isDbTableSameAsColsTable(db: DbConn, tablename: string, table: OrderedTable[string, string]) =
  ## We use this procedure to compare two tables against each other and see if there are any mismatches.
  ## A mismatch could signify someone forgetting to complete the migration instructions.
  var cols: seq[string] = @[] # To store the columns that are currently in the database
  var missing: seq[string] = @[] # To store the columns missing from the database.

  for row in db.all("PRAGMA table_info('" & tablename & "');"):
    cols.add(row[1].strVal)

  for key in table.keys:
    if key notin cols:
      missing.add(key)

  if len(missing) > 0:
    log "Major difference between built-in schema and currently-used schema"
    log "Did you forget to migrate? Please migrate before re-running this program"
    error "Missing columns from " & tablename & " schema:\n" & $missing

proc init*(config: Table[string, string], schemaCheck: bool = true): DbConn  =
  # Some checks to run before we actually open the database
  if not config.exists("db","filename"):
    log "Couldn't find mandatory key \"filename\" in section \"db\""
    log "Using \"main.db\" as substitute instead"

  let fn = config.getStringOrDefault("db","filename","main.db")

  log "Opening sqlite3 database at ", fn

  if fn.startsWith("__eat_flaming_death"):
    log "Someone or something used the forbidden code. Quietly returning... Stuff might break!"
    return

  # Open database and initialize the users and posts table.
  result = openDatabase(fn)
  
  # Create the tables first
  if not createDbTableWithColsTable(result, "users", usersCols): error "Couldn't create users table!"
  if not createDbTableWithColsTable(result, "posts", postsCols): error "Couldn't create posts table!"

  # Now we check the schema to make sure it matches the hard-coded one.
  if schemaCheck:
    isDbTableSameAsColsTable(result, "users", usersCols)
    isDbTableSameAsColsTable(result, "posts", postsCols)

  return result

proc quickInit*(config: Table[string, string]): DbConn = 
  ## This procedure quickly initializes the database by skipping a bunch of checks.
  ## It assumes that you have done these checks on startup by running the regular init() proc once.
  return openDatabase(config.getStringOrDefault("db","filename","main.db"))

proc uninit*(db: DbConn): bool =
  ## Uninitialize the database.
  ## Or close it basically...
  try:
    db.close()
  except CatchableError as err:
    error "Couldn't close the database: " & err.msg

proc addUser*(db: DbConn, user: User): bool = 
  
  ## Add a user to the database
  ## This procedure expects an escaped user to be handed to it.
  if db.has("SELECT local FROM users WHERE handle = " & user.handle & ";"):
    log "User with handle " & user.handle & " already exists!"
    return false # Simply exit

  if db.has("SELECT local FROM users WHERE id = " & user.id & ";"):
    log "User with id " & user.id & " already exists!"
    return false # Return false if id already exists

  # Now we loop over the fields and build an SQL statement as we go.
  var sqlStatement = "INSERT INTO users("

  for key, value in user.fieldPairs:
    sqlStatement.add(key & ",")
  
  sqlStatement = sqlStatement[0 .. ^2]
  sqlStatement.add(") VALUES (")

  for key, value in user.fieldPairs:
    when typeof(value) is string:
      sqlStatement.add(value)
    when typeof(value) is bool:
      sqlStatement.add($value)
    when typeof(value) is int:
      sqlStatement.add($value)
    when typeof(value) is UserType:
      sqlStatement.add(escape(fromUserType(value)))
    sqlStatement.add(",")
  

  sqlStatement = sqlStatement[0 .. ^2]
  sqlStatement.add(");")

  try:
    db.exec(sqlStatement)
  except:
    log "sqlStatement: " & sqlStatement
    when not defined(phPrivate):
      log "Failed to insert user!"
      return
    else:
      error "Failed to insert user!"

  return true

proc getAdmins*(db: DbConn): seq[string] = 
  ## A procedure that returns the usernames of all administrators.
  for row in db.all("SELECT handle FROM users WHERE admin = true;"):
    result.add(row[0].strVal.unescape("",""))
  return result
  
proc getTotalLocalUsers*(db: DbConn): int =
  ## A procedure to get the total number of local users.
  result = 0
  for x in db.all("SELECT handle FROM users WHERE local = true;"):
    inc(result)
  return result

proc userIdExists*(db: DbConn, id:string): bool =
  ## A procedure to check if a user exists by id
  ## This procedures does escape IDs by default.
  return db.has("SELECT local FROM users WHERE id = " & escape(id) & ";")

proc userHandleExists*(db: DbConn, handle:string): bool =
  ## A procedure to check if a user exists by handle
  ## This procedure does sanitize and escape handles by default
  return db.has("SELECT local FROM users WHERE handle = " & escape(sanitizeHandle(handle)) & ";")

proc constructUserFromRow*(row: ResultRow): User =
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
      result.get(key) = parseBool($(row[i].intVal))
    when result.get(key) is string:
      result.get(key) = row[i].strVal
    when result.get(key) is int:
      result.get(key) = int64ToInt(row[i].intVal)
    when result.get(key) is UserType:
      result.get(key) = toUserType(unescape(row[i].strVal,"",""))

  return result.unescape()

proc getUserById*(db: DbConn, id: string): User =
  ## Retrieve a user from the database using their id
  ## This procedure returns a fully unescaped user, you do not need to do anything to it.
  ## This procedure expects a regular ID, it will sanitize and escape it by default.
  if not db.userIdExists(id):
    error "Something or someone tried to get a non-existent user with the id \"" & id & "\""

  return constructUserFromRow(db.one("SELECT * FROM users WHERE id = " & escape(id) & ";").get)

proc getUserByHandle*(db: DbConn, handle: string): User =
  ## Retrieve a user from the database using their handle
  ## This procedure returns a fully unescaped user, you do not need to do anything to it.
  ## This procedure expects a regular handle, it will sanitize and escape it by default.
  if not db.userHandleExists(handle):
    error "Something or someone tried to get a non-existent user with the handle \"" & handle & "\""
    
  return constructUserFromRow(db.one("SELECT * FROM users WHERE handle = " & escape(sanitizeHandle(handle)) & ";").get)

proc update(db: DbConn, table, condition, column, value: string): bool =
  ## A procedure to update any value, in any column in any table.
  ## This procedure should be wrapped, you can use updateUserByHandle() or
  ## updateUserById() instead of using this directly.
  var sqlStatement = "UPDATE " & table & " SET " & column & " = " & value & " WHERE " & condition & ";"
  try:
    db.exec(sqlStatement)
    return true
  except:
    return false

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

#! This comment marks the beginning of the Post section.
# Procedures here are primarily used for posts.

proc constructPostFromRow*(row: ResultRow): Post =
  ## A procedure that takes a database Row (From the Posts table)
  ## And turns it into a Post object ready for display, parsing and so on. (That is to say, the final Post is unescaped and does not need further action.)
  result = Post()
  
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
      result.get(key) = parseBool($(row[i].intval))
    when result.get(key) is string:
      result.get(key) = row[i].strVal
    when result.get(key) is seq[string]:
      result.get(key) = split(row[i].strVal, ",")

      # the split() proc sometimes creates items in the sequence
      # even when there isn't. So this bit of code manually
      # clears the list if two specific conditions are met.
      if len(result.get(key)) == 1 and result.get(key)[0] == "":
        result.get(key) = @[]
    when result.get(key) is Table[string, string]:
      if len(row[i].strVal) > 0:
        result.get(key) = toTable(row[i].strVal)
    when result.get(key) is DateTime:
      result.get(key) = toDate(row[i].strVal)

  return result

proc addPost*(db: DbConn, post: Post): bool =
  ## A function add a post into the database
  ## This function uses parameterized substitution Aka. prepared statements.
  ## So escaping objects before sending them here is not a requirement.
  
  var testString = ""
  if post.id.startsWith('\"'):
    testString = "SELECT local FROM posts WHERE id = " & post.id & ";"
  else:
    testString = "SELECT local FROM posts WHERE id = \"" & post.id & "\";"

  if db.has(testString):
    return false # Someone has tried to add a post twice. We just won't add it.

  # Let's loop over the newuser field pairs and
  # Build the SQL statement as we go.
  var
    sqlStatement = "INSERT OR REPLACE INTO posts ("
    i = -1

  for key, val in post.fieldPairs:
    inc(i)
    sqlStatement.add(key & ",")
  
  # Remove last character
  sqlStatement = sqlStatement[0 .. ^2]

  # Add the missing part
  sqlStatement.add(") VALUES (")

  # The other part of the SQL statement
  # The question marks (for parameter substitution)
  sqlStatement.add("?,")
  for x in 1 .. i:
    sqlStatement.add(" ?,")

  sqlStatement = sqlStatement[0 .. ^2]
  sqlStatement.add(");")

  
  # TODO: Automate this some day.
  # I believe we can use a template or a macro to automate inserting this stuff in.
  try:
    db.exec(
      sqlStatement,
      post.id,
      toString(post.recipients),
      post.sender,
      post.replyto,
      post.content,
      toString(post.written),
      toString(post.updated),
      post.modified,
      post.local,
      toString(post.favorites),
      toString(post.boosts),
      toString(post.revisions)
    )
  except CatchableError as err:
    log "sqlStatement: " & sqlStatement
    error "Failed to insert post: ", err.msg

  return true

proc postIdExists*(db: DbConn, id: string): bool =
  ## A function to see if a post id exists in the database
  ## The id supplied can be plain and un-escaped. It will be escaped and sanitized here.
  return db.has("SELECT local FROM posts WHERE id = " & escape(id) & ";")

proc updatePost*(db: DbConn, id, column, value: string): bool =
  ## A procedure to update a post using it's ID.
  ## Like with the updateUserByHandle and updateUserById procedures,
  ## the value parameter should be heavily sanitized and escaped to prevent a class of awful security holes.
  ## The id can be passed plain, it will be escaped.
  db.update("posts","id = " & escape(id), column, value)

proc getPost*(db: DbConn, id: string): Post =
  ## A procedure to get a post object using it's ID.
  ## The id can be passed plain, it will be escaped.
  ## The output will be an unescaped
  var post = db.one("SELECT * FROM posts WHERE id = " & escape(id) & ";")
  if isNone(post):
    error "Something or someone tried to retrieve a non-existent post with the ID of \"" & id & "\""

  return constructPostFromRow(post.get)

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
      result.add(constructPostFromRow(post))
  else:
    for post in db.all(sqlStatement):
      result.add(constructPostFromRow(post))
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
  var sqlStatement = "SELECT * FROM posts WHERE local = true;"
  if limit != 0:
    for row in db.all(sqlStatement):
      if len(result) > limit:
        break
      result.add(constructPostFromRow(row))
  else:
    for row in db.all(sqlStatement):
      result.add(constructPostFromRow(row))
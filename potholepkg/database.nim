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
# database.nim:
## Database backend for pothole, this engine is powered via postgres
## (more specifically, the standard db_connector/db_postgres module)
## This backend is still not working yet.

# From somewhere in Pothole
import lib, conf, user

# From somewhere in the standard library
import std/strutils

# Export these:
import db/[users, posts, reactions, boosts, common, postrevisions]
export DbConn, isNil, users, posts, reactions, boosts, postrevisions, getDbHost, getDbName, getDbPass, getDbUser

const databaseTables = @[
  ## Add an extra field to this whenever you need to insert a new table.
  ## + cleanDb() depends on this! So no need to add a new table there!
  ("users", usersCols),
  ("posts", postsCols),
  ("postsRevisions", postsRevisionsCols),
  ("reactions", reactionsCols),
  ("boosts", boostsCols)
]

proc setup*(config: ConfigTable, schemaCheck: bool = true, quiet: bool = false): DbConn  =
  # Some checks to run before we actually open the database

  if not hasDbHost(config) and not quiet:
    log "Couldn't retrieve database host. Using \"127.0.0.1:5432\" as default"
    log ""

  if not hasDbName(config) and not quiet:
    log "Couldn't retrieve database name. Using \"pothole\" as default"

  if not hasDbUser(config) and not quiet:
    log "Couldn't retrieve database user login. Using \"pothole\" as default"
  
  if not hasDbPass(config) and not quiet:
    log "Couldn't find database user password from the config file or environment, did you configure pothole correctly?"
    error "Database user password couldn't be found."

  let
    host = getDbHost(config)
    name = getDbName(config)
    user = getDbUser(config)
    password = getDbPass(config)

  if not quiet: log "Opening database \"", name ,"\" at \"", host, "\" with user \"", user, "\""

  if host.startsWith("__eat_flaming_death") and not quiet:
    log "Someone or something used the forbidden code. Quietly returning... Stuff might break!"
    return

  # Open database and initialize the users and posts table.
  result = open(host, user, password, name)
  
  for i in databaseTables:
    # Create the tables first
    if not createDbTable(result, i[0], i[1]):
      if quiet: quit(1)
      error "Failed to create ", i[0], " table"
    
    # Now we check the schema to make sure it matches the hard-coded one.
    if schemaCheck:
      matchTableSchema(result, i[0], i[1])
  
  # Add `null` user
  # `null` is used by pothole to signify a deleted user.
  # Fx. imagine a user deletes their account, the database schema requires that we 
  # have a valid sender in every single post.
  # And so `null` acts a sender in that scenario.
  var null = newUser(
    "null",
    true,
    ""
  )
  # The `null` user must have a "null" id.
  null.id = "null"
  null.is_frozen = true
  null.salt = ""
  null.name = "Deleted User"
  if not result.userIdExists("null"):
    discard result.addUser(null)

  return result

proc init*(config: ConfigTable): DbConn = 
  ## This procedure quickly initializes the database by skipping a bunch of checks.
  ## It assumes that you have done these checks on startup by running the regular setup() proc once.
  try:
    return open(
      config.getDbHost(),
      config.getDbUser(),
      config.getDbPass(),
      config.getDbName()
    )
  except CatchableError as err:
    log "Did you forget to start the postgres database server?"
    error "Couldn't connect to postgres: ", err.msg

proc uninit*(db: DbConn): bool =
  ## Uninitialize the database.
  ## Or close it basically...
  try:
    db.close()
  except CatchableError as err:
    error "Couldn't close the database: " & err.msg

proc isNil*(db: DbConn): bool =
  # The old check (line below) errors out with a storage acess error and I am not sure how to fix it.
  # return db[].dbName.len() == 0
  # TODO: If this could be fixed then that would be great
  return false

proc cleanDb*(db: DbConn) =
  for i in databaseTables:
    try:  
      db.exec(sql("DROP TABLE IF EXISTS " & i[0] & " CASCADE;"))
    except CatchableError as err:
      error "Couldn't clean database ", i[0], ": ", err.msg
  
proc cleanDb*(config: ConfigTable) =
  database.init(config).cleanDb()
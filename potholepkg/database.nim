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
import lib, conf

# From somewhere in the standard library

# Export these:
import db/[users, posts, reactions, boosts, common]
#export DbConn, isOpen, users, posts, reactions, boosts
import db/common

when (NimMajor, NimMinor, NimPatch) >= (1, 7, 3):
  include db_connector/db_postgres
else:
  include db_postgres

proc init*(config: Table[string, string], schemaCheck: bool = true): DbConn  =
  # Some checks to run before we actually open the database

  if not hasDbHost(config):
    log "Couldn't retrieve database host. Using \"127.0.0.1:5432\" as default"
    log ""

  if not hasDbName(config):
    log "Couldn't retrieve database name. Using \"pothole\" as default"

  if not hasDbUser(config):
    log "Couldn't retrieve database user login. Using \"pothole\" as default"
  
  if not hasDbPass(config):
    log "Couldn't find database user password from the config file or environment, did you configure pothole correctly?"
    error "Database user password couldn't be found."

  let
    host = getDbHost(config)
    name = getDbName(config)
    user = getDbUser(config)
    password = getDbPass(config)

  log "Opening database \"", name ,"\"at \"", host, "\" with user \"", user, "\""

  if host.startsWith("__eat_flaming_death"):
    log "Someone or something used the forbidden code. Quietly returning... Stuff might break!"
    return

  # Open database and initialize the users and posts table.
  result = open(host, user, password, name)
  
  # Create the tables first
  if not createDbTableWithColsTable(result, "users", usersCols): error "Couldn't create users table"
  if not createDbTableWithColsTable(result, "posts", postsCols): error "Couldn't create posts table"
  if not createDbTableWithColsTable(result, "reactions", reactionsCols): error "Couldn't create reactions table"
  if not createDbTableWithColsTable(result, "boosts", boostsCols): error "Couldn't create boosts table"

  # Now we check the schema to make sure it matches the hard-coded one.
  if schemaCheck:
    matchTableSchema(result, "users", usersCols)
    matchTableSchema(result, "posts", postsCols)
    matchTableSchema(result, "posts", postsCols)
    matchTableSchema(result, "reactions", reactionsCols)
    matchTableSchema(result, "boosts", boostsCols)

  return result

proc quickInit*(config: Table[string, string]): DbConn = 
  ## This procedure quickly initializes the database by skipping a bunch of checks.
  ## It assumes that you have done these checks on startup by running the regular init() proc once.
  return open(
    getDbHost(config),
    getDbUser(config),
    getDbPass(config),
    getDbName(config)
  )

proc uninit*(db: DbConn): bool =
  ## Uninitialize the database.
  ## Or close it basically...
  try:
    db.close()
  except CatchableError as err:
    error "Couldn't close the database: " & err.msg
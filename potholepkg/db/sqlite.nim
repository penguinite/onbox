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
import ../[lib, conf]

# From somewhere in the standard library
import std/strutils except isEmptyOrWhitespace
import std/[tables]

# From somewhere else (nimble etc.)
import tiny_sqlite

# Export these:
import sqlite/[users, posts, reactions, boosts, common]
export DbConn, isOpen, users, posts, reactions, boosts

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
  if not createDbTableWithColsTable(result, "users", usersCols): error "Couldn't create users table"
  if not createDbTableWithColsTable(result, "posts", postsCols): error "Couldn't create posts table"
  if not createDbTableWithColsTable(result, "reactions", reactionsCols): error "Couldn't create reactions table"
  if not createDbTableWithColsTable(result, "boosts", boostsCols): error "Couldn't create boosts table"

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
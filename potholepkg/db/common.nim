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
# db/sqlite/common.nim:
## This module contains all the common procedures used across the entire database.

import ../[lib, conf]

# From somewhere in the standard library
import std/strutils except isEmptyOrWhitespace, parseBool
import std/[tables, os]

# From somewhere else (nimble etc.)
import db_connector/db_postgres
export db_postgres

proc createDbTable*(db: DbConn, tablename: string, cols: OrderedTable[string,string]):  bool =
  ## We use this procedure to create a SQL statement that creates a table using the hard-coded rules
  # We build the sql statement slowly.
  var sqlStatement = "CREATE TABLE IF NOT EXISTS " & tablename & " ("
  for key, value in cols.pairs:
    if key.startsWith("__"):
      sqlStatement.add("$#," % [value])
    else:
      sqlStatement.add("$# $#," % [key, value])
  sqlStatement = sqlStatement[0 .. ^2] # Remove last comma
  sqlStatement.add(");") # Add final two characters

  # Now we run and hope for the best!
  try:
    db.exec(sql(sqlStatement))
    return true
  except CatchableError as err:
    log "Error whilst creating table " & tablename & ": " & err.msg
    return false

proc exec*(db: DbConn, stmet: string, args: varargs[string, `$`]) =
  exec(db,sql(stmet),args)

proc update*(db: DbConn, table, condition, column, value: string): bool =
  ## A procedure to update any value, in any column in any table.
  ## This procedure should be wrapped, you can use updateUserByHandle() or
  ## updateUserById() instead of using this directly.
  var sqlStatement = "UPDATE " & table & " SET " & column & " = " & value & " WHERE " & condition & ";"
  try:
    db.exec(sqlStatement)
    return true
  except:
    return false

proc matchTableSchema*(db: DbConn, tablename: string, table: OrderedTable[string, string]) =
  ## We use this procedure to compare two tables against each other and see if there are any mismatches.
  ## A mismatch could signify someone forgetting to complete the migration instructions.
  var cols: seq[string] = @[] # To store the columns that are currently in the database
  var missing: seq[string] = @[] # To store the columns missing from the database.


proc hasDbHost*(config: ConfigTable): bool =
  if config.exists("db","host") or existsEnv("PHDB_HOST"):
    return true
  return false

proc getDbHost*(config: ConfigTable): string =
  ## This procedure returns a string containing the name of the database we want to use.
  ## It has a default value of "127.0.0.1:5432" but overrides it based on the config or environment variables (In that order)
  result = "127.0.0.1:5432"

  if config.exists("db","host"):
    result = config.getString("db","host")

  if existsEnv("PHDB_HOST"):
    result = getEnv("PHDB_HOST")

  return result

proc hasDbName*(config: ConfigTable): bool =
  if config.exists("db","name") or existsEnv("PHDB_NAME"):
    return true
  return false

proc getDbName*(config: ConfigTable): string =
  ## This procedure returns a string containing the name of the database we want to use.
  ## It has a default value of "pothole" but overrides it based on the config or environment variables (In that order)
  result = "pothole"

  if config.exists("db","name"):
    result = config.getString("db","name")

  if existsEnv("PHDB_NAME"):
    result = getEnv("PHDB_NAME")
  
  return result

proc hasDbUser*(config: ConfigTable): bool =
  if config.exists("db","user") or existsEnv("PHDB_USER"):
    return true
  return false

proc getDbUser*(config: ConfigTable): string =
  ## This procedure returns a string containing the name of the database we want to use.
  ## It has a default value of "pothole" but overrides it based on the config or environment variables (In that order)
  result = "pothole"

  if config.exists("db","user"):
    result = config.getString("db","user")

  if existsEnv("PHDB_USER"):
    result = getEnv("PHDB_USER")
  
  return result

proc hasDbPass*(config: ConfigTable): bool =
  if config.exists("db","password") or existsEnv("PHDB_PASS"):
    return true
  return false

proc getDbPass*(config: ConfigTable): string =
  ## This procedure returns a string containing the name of the database we want to use.
  ## It has no default value but overrides it based on the config or environment variables (In that order)
  ## 
  if existsEnv("PHDB_PASS"):
    return getEnv("PHDB_PASS")

  if config.exists("db","password"):
    return config.getString("db","password")

  return ""

proc has*(row: Row): bool =
  ## A quick helper function to check if a Row is valid.
  return len(row) != 0 and row[0] != ""
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

import ../../lib

# From somewhere in the standard library
import std/strutils except isEmptyOrWhitespace
import std/[tables, options]

# From somewhere else (nimble etc.)
import tiny_sqlite

proc createDbTableWithColsTable*(db: DbConn, tablename: string, cols: OrderedTable[string,string]):  bool =
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

proc isDbTableSameAsColsTable*(db: DbConn, tablename: string, table: OrderedTable[string, string]) =
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

proc has*(row: Option[ResultRow]): bool =
  ## A quick helper function to check if a thing exists.
  if isNone(row):  
    return false
  return true
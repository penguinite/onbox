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
# db/sqlite/boosts.nim:
## This module contains all database logic for handling boosts.

import ../crypto

import common

# From somewhere in the standard library
import std/tables

# From somewhere else (nimble etc.)
when (NimMajor, NimMinor, NimPatch) >= (1, 7, 3):
  include db_connector/db_postgres
else:
  include db_postgres

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
const boostsCols*: OrderedTable[string, string] = {"id": "BLOB PRIMARY KEY UNIQUE NOT NULL",
"pid": "BLOB NOT NULL", # ID of post that user boosted
"uid": "BLOB NOT NULL", # ID of user that boosted post
"level": "BLOB NOT NULL" # The "boost level", ie. is it followers-only or whatever.
}.toOrderedTable

proc getBoosts*(db: DbConn, id: string): Table[string, seq[string]] =
  ## Retrieves a Table of boosts for a post.
  let preResult = db.getRow(sql"SELECT uid,level FROM boosts WHERE pid = ?;", id)
  echo preResult
  return

proc addBoost*(db: DbConn, pid,uid,level: string): bool =
  ## Adds an individual boost
  # Check for ID first.
  var id = randomString(8)
  while has(db.getRow(sql"SELECT id FROM boosts WHERE id = ?;", id)):
    id = randomString(8)

  db.exec(sql"INSERT OR REPLACE INTO boosts (id, pid, uid, level) VALUES (?,?,?,?);",id,pid,uid,level)

proc addBulkBoosts*(db: DbConn, id: string, table: Table[string, seq[string]]) =
  ## Adds an entire table of boosts to the database
  for boost,list in table.pairs:
    for user in list:
      discard db.addBoost(id, user, boost)

proc removeBoost*(db: DbConn, pid,uid: string) =
  ## Removes a boost from the database
  db.exec("DELETE FROM boosts WHERE pid = ? AND uid = ?;",pid,uid)

proc hasBoost*(db: DbConn, pid,uid,level: string): bool =
  ## Checks if a post has a boost. Everything must match.
  if has(db.getRow(sql"SELECT id FROM boosts WHERE pid = ? AND uid = ? AND level = ?;", pid, uid, level)):
    return true
  return false
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
# db/sqlite/reactions.nim:
## This module contains all database logic for handling reactions.

import ../../crypto

# From somewhere in the standard library
import std/tables

# From somewhere else (nimble etc.)
import tiny_sqlite

import common

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
const reactionsCols*: OrderedTable[string, string] = {"id": "BLOB PRIMARY KEY UNIQUE NOT NULL",
"pid": "BLOB UNIQUE NOT NULL", # ID of post that user reacted to
"uid": "BLOB UNIQUE NOT NULL", # ID of user who reacted to post
"reaction": "BLOB NOT NULL" # Specific reaction
}.toOrderedTable

proc getReactions*(db: DbConn, id: string): Table[string, seq[string]] =
  let statement = db.stmt("SELECT uid,reaction FROM reactions WHERE pid = ?;")
  echo statement.all(id)
  statement.finalize()

proc addReaction*(db: DbConn, pid,uid,reaction: string): bool =
  let
    testStatement = db.stmt("SELECT 1 FROM reactions WHERE id = ?;")
    statement = db.stmt("INSERT OR REPLACE INTO reactions (id, pid, uid, reaction) VALUES (?,?,?,?);")
  try:
    var id = randomString()
    while has(testStatement.one(id)):
      id = randomString()

    statement.exec(id, pid, uid, reaction)
    statement.finalize()
  except:
    statement.finalize()

proc addBulkReactions*(db: DbConn, id: string, table: Table[string, seq[string]]) =
  for reaction,list in table.pairs:
    for user in list:
      discard db.addReaction(id, user, reaction)

proc removeReaction*(db: DbConn, pid,uid: string) =
  let statement = db.stmt("DELETE FROM reactions WHERE pid = ? AND uid = ?;")
  statement.exec(pid,uid)
  statement.finalize()
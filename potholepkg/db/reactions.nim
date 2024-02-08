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

import ../crypto

# From somewhere in the standard library
import std/tables

import common

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
const reactionsCols*: OrderedTable[string, string] = {"id": "TEXT PRIMARY KEY",
"pid": "TEXT NOT NULL", # ID of post that user reacted to
"uid": "TEXT NOT NULL", # ID of user who reacted to post
"reaction": "TEXT NOT NULL" # Specific reaction
}.toOrderedTable

proc getReactions*(db: DbConn, id: string): Table[string, seq[string]] =
  ## Retrieves a Table of reactions for a post.
  let preResult = db.getRow(sql"SELECT uid,reaction FROM reactions WHERE pid = ?;", id)
  echo preResult
  return

proc addReaction*(db: DbConn, pid,uid,reaction: string): bool =
  ## Adds an individual reaction
  # Check for ID first.
  var id = randomString(8)
  while has(db.getRow(sql"SELECT id FROM reactions WHERE id = ?;", id)):
    id = randomString(8)

  db.exec(sql"INSERT OR REPLACE INTO reactions (id, pid, uid, reaction) VALUES (?,?,?,?);",id,pid,uid,reaction)

proc addBulkReactions*(db: DbConn, id: string, table: Table[string, seq[string]]) =
  ## Adds an entire table of reactions to the database
  for reaction,list in table.pairs:
    for user in list:
      discard db.addReaction(id, user, reaction)

proc removeReaction*(db: DbConn, pid,uid: string) =
  ## Removes a reactions from the database
  db.exec("DELETE FROM reactions WHERE pid = ? AND uid = ?;",pid,uid)

proc hasReaction*(db: DbConn, pid,uid,reaction: string): bool =
  ## Checks if a post has a reaction. Everything must match.
  if has(db.getRow(sql"SELECT id FROM reactions WHERE pid = ? AND uid = ? AND reaction = ?;", pid, uid, reaction)):
    return true
  return false
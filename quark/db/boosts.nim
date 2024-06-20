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
import ../private/database
import users

# From somewhere in the standard library
import std/tables

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
const boostsCols*: OrderedTable[string, string] = {"id": "TEXT PRIMARY KEY NOT NULL",
"pid": "TEXT NOT NULL", # ID of post that user boosted
"uid": "TEXT NOT NULL", # ID of user that boosted post
"level": "TEXT NOT NULL", # The "boost level", ie. is it followers-only or whatever.
"__A": "foreign key (pid) references posts(id)", # Some foreign key for integrity
"__B": "foreign key (uid) references users(id)", # Same as above
}.toOrderedTable

proc getBoosts*(db: DbConn, id: string): Table[string, seq[string]] =
  ## Retrieves a Table of boosts for a post. Result consists of a table where the keys are the specific levels and the value is a sequence of boosters associated with this level.
  for row in db.getAllRows(sql"SELECT uid,level FROM boosts WHERE pid = ?;", id):
    result[row[1]].add(row[0])
  return result

proc getBoostsQuick*(db: DbConn, id: string): seq[string] =
  ## Returns a list of boosters for a specific post
  for row in db.getAllRows(sql"SELECT uid,level FROM boosts WHERE pid = ?;", id):
    # Obviously don't add private boosts to the public list.
    if row[1] == "Private" or row[1] == "FollowersOnly":
      continue
    result.add(row[0])
  return result

proc getBoostsQuickWithHandle*(db: DbConn, id: string): seq[string] =
  ## Returns a list of boosters for a specific post, used when rendering /users/USER.
  ## This is the exact same thing as above but we call the db to convert the ids into handles.
  for id in db.getBoostsQuick(id):
    result.add(db.getHandleFromId(id))
  return result

proc addBoost*(db: DbConn, pid,uid,level: string) =
  ## Adds an individual boost
  # Check for ID first.
  var id = randstr(8)
  while has(db.getRow(sql"SELECT id FROM boosts WHERE id = ?;", id)):
    id = randstr(8)

  db.exec(sql"INSERT INTO boosts (id, pid, uid, level) VALUES (?,?,?,?);",id,pid,uid,level)

proc addBulkBoosts*(db: DbConn, id: string, table: Table[string, seq[string]]) =
  ## Adds an entire table of boosts to the database
  for boost,list in table.pairs:
    for user in list:
      db.addBoost(id, user, boost)

proc removeBoost*(db: DbConn, pid,uid: string) =
  ## Removes a boost from the database
  db.exec("DELETE FROM boosts WHERE pid = ? AND uid = ?;",pid,uid)

proc hasBoost*(db: DbConn, pid,uid,level: string): bool =
  ## Checks if a post has a boost. Everything must match.
  if has(db.getRow(sql"SELECT id FROM boosts WHERE pid = ? AND uid = ? AND level = ?;", pid, uid, level)):
    return true
  return false
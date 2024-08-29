# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
# Copyright © penguinite 2024 <penguinite@tuta.io>
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
# quark/db/boosts.nim:
## This module contains all database logic for handling boosts.
## A "boost" is used to promote posts, putting them on a user's profile
## and thus visible to a user's followers.
## 
## There are kinds of boosts, hence why we store an extra "level" column
## Someone might want to show a post to only their followers and no where else.
## Quote-boosts are not considered true boosts. They're just posts with a link.

import ../private/database
import users

# From somewhere in the standard library
import std/tables

const boostsCols* = @[
  # The ID for the boost
  "id TEXT PRIMARY KEY NOT NULL",
  # ID of post that user boosted
  "pid TEXT NOT NULL", 
  # ID of user that boosted post
  "uid TEXT NOT NULL", 
  # The "boost level", ie. is it followers-only or whatever.
  "level TEXT NOT NULL", 

  # Some foreign keys for integrity
  "foreign key (pid) references posts(id)", 
  "foreign key (uid) references users(id)"
]

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

proc getNumOfBoosts*(db: DbConn, pid: string): int =
  for i in db.getAllRows(sql"SELECT id FROM boosts WHERE pid = ?;", pid):
    inc(result)
  return result

proc addBulkBoosts*(db: DbConn, id: string, table: Table[string, seq[string]]) =
  ## Adds an entire table of boosts to the database
  for boost,list in table.pairs:
    for user in list:
      db.addBoost(id, user, boost)

proc removeBoost*(db: DbConn, pid,uid: string) =
  ## Removes a boost from the database
  db.exec(sql"DELETE FROM boosts WHERE pid = ? AND uid = ?;",pid,uid)

proc hasBoost*(db: DbConn, pid,uid,level: string): bool =
  ## Checks if a post has a boost. Everything must match.
  return has(db.getRow(sql"SELECT id FROM boosts WHERE pid = ? AND uid = ? AND level = ?;", pid, uid, level))

proc hasAnyBoost*(db: DbConn, pid,uid: string): bool =
  ## Checks if a post has a boost. Everything must match.
  return has(db.getRow(sql"SELECT id FROM boosts WHERE pid = ? AND uid = ?;", pid, uid))
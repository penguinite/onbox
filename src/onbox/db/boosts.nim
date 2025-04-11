# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This file is part of Onbox.
# 
# Onbox is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Onbox is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Onbox. If not, see <https://www.gnu.org/licenses/>. 
#
# onbox/db/boosts.nim:
## This module contains all database logic for handling boosts.
## A "boost" is used to promote posts, putting them on a user's profile
## and thus visible to a user's followers.

# There are different kinds of boosts, hence why we store an extra "level" column
# Someone might want to show a post to only their followers and no one else.
# Quote-boosts are not considered true boosts. They're just posts with a link.

# From Onbox
import ../[shared, strextra]

# From somewhere in the standard library
import std/tables

# From third-parties
import db_connector/db_postgres

proc getBoosts*(db: DbConn, id: string): Table[PostPrivacyLevel, seq[string]] =
  ## Retrieves a Table of boosts for a post.
  ## Result consists of a table where the keys are the specific levels and
  ## the value is a sequence of boosters associated with this level.
  for row in db.getAllRows(sql"SELECT uid,level FROM boosts WHERE pid = ?;", id):
    result[toLevel(row[1])].add(row[0])

proc getBoostsQuick*(db: DbConn, id: string): seq[string] =
  ## Returns a list of boosters for a specific post.
  # TODO: Adding an extra for loop here seems dumb...
  # But getAllRows returns seq[Row] (which is like seq[seq[string]])
  for row in db.getAllRows(sql"SELECT uid FROM boosts WHERE pid = ?;", id):
    result.add(row[0])

proc isBoostable*(db: DbConn, pid: string): bool =
  ## Checks if the post can be boosted.
  ##
  ## Currently, this only checks if the post you're trying to boost
  ## is either a public or unlisted post.
  # TODO: This might be wrong.
  toLevel(db.getRow(sql"SELECT privacy_level FROM posts WHERE id = ?;", pid)[0]) in [Public, Unlisted]

proc userBoosted*(db: DbConn, uid, pid: string): bool =
  ## Check if a user has boosted a post
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM boosts WHERE pid = ? AND uid = ?);",
    pid, uid
  )[0] == "t"

proc removeBoost*(db: DbConn, pid,uid: string) =
  ## Removes a boost from the database
  db.exec(sql"DELETE FROM boosts WHERE pid = ? AND uid = ?;",pid,uid)

proc userBoostedLevel*(db: DbConn, pid,uid: string, level: PostPrivacyLevel): bool =
  ## Checks if a post has a boost by a specific user, with a specific level too.
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM boosts WHERE pid = ? AND uid = ? AND level = ?);",
    pid, uid, !$level
  )[0] == "t"

proc addBoost*(db: DbConn, pid,uid: string, level: PostPrivacyLevel) =
  ## Adds an individual boost
  
  # Check if a boost already exists before
  # &
  # Filter out invalid levels.
  # You can't have a boost limited to some unknown people
  # and a "private boost" (that is just a bookmark lol)
  if not db.userBoosted(uid, pid) and level notin {Limited, Private}:
    db.exec(sql"INSERT INTO boosts (pid, uid, level) VALUES (?,?,?);",pid,uid, !$(level))

proc getNumOfBoosts*(db: DbConn, pid: string): int =
  return len(db.getAllRows(sql"SELECT 0 FROM boosts WHERE pid = ?;", pid))
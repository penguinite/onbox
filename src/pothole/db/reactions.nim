# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
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
# db/reactions.nim:
## This module contains all database logic for handling reactions.
## Reactions include likes, favorites or whatever.
## They're flexible by design.

# From standard library
import std/tables

# From third-parties
import db_connector/db_postgres

proc getReactions*(db: DbConn, post: string): Table[string, seq[string]] =
  ## Retrieves a Table of reactions for a post.
  ## Result consists of a table where the keys are the specific reaction and
  ## the value is a sequence of reactors.
  for row in db.getAllRows(sql"SELECT uid,reaction FROM reactions WHERE pid = ?;", post):
    result[row[1]].add(row[0])

proc getNumOfReactions*(db: DbConn, post: string): int =
  len(db.getAllRows(sql"SELECT 0 FROM reactions WHERE pid = ?;", post))

proc hasReaction*(db: DbConn, user, post, reaction: string): bool =
  ## Checks if a post has a reaction. Everything must match.
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM reactions WHERE pid = ? AND uid = ? AND reaction = ?);",
    post, user, reaction
  )[0] == "t"

proc hasAnyReaction*(db: DbConn, user, post: string): bool =
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM reactions WHERE pid = ? AND uid = ?);", post, user
  )[0] == "t"

proc addReaction*(db: DbConn, user, post, reaction: string) =
  ## Adds an individual reaction
  db.exec(sql"INSERT INTO reactions VALUES (?,?,?);",post,user,reaction)

proc removeReaction*(db: DbConn, user, post: string) =
  ## Removes a reactions from the database
  db.exec(sql"DELETE FROM reactions WHERE pid = ? AND uid = ?;",post,user)

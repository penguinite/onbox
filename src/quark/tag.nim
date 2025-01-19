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
# quark/db/tag.nim:
## This module contains all database logic for handling hashtags!
## Including creation, retrieval, checking, updating and deletion
import quark/private/database, quark/shared, std/times
export shared, times

proc tagExists*(db: DbConn, tag: string): bool =
  return has(db.getRow(sql"SELECT trendable FROM tag WHERE name = ?;", tag))

proc getTagUrl*(db: DbConn, tag: string): string =
  return db.getRow(sql"SELECT url FROM tag WHERE name = ?;", tag)[0]

proc createTag*(db: DbConn, name: string, url = "", desc = "", trendable = true, usable = true, requires_review = false, system = false) =
  ## Creates a new tag object in the database and returns the ID associated with it.
  db.exec(
    sql"INSERT INTO tag VALUES (?,?,?,?,?,?,?);",
    name, url, desc, trendable, usable, requires_review, system
  )


# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
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
# onbox/db/bookmarks.nim:
## This module contains all database logic for handling user bookmarks.
## Including creation, retrieval, checking, updating and deletion
import db_connector/db_postgres

proc bookmarkExists*(db: DbConn, user, post: string): bool =
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM bookmarks WHERE uid = ? AND pid = ?);",
    user, post
  )[0] == "t"

proc bookmarkPost*(db: DbConn, user, post: string) =
  db.exec(sql"INSERT INTO bookmarks VALUES (?,?);", post, user)

proc getBookmarks*(db: DbConn, user: string, limit = 20): seq[string] =
  ## Returns a sequence of post IDs that a user has bookmarked.
  ## 
  ## Note: This has a limit, by default 20.
  for row in db.getAllRows(sql("SELECT pid FROM bookmarks WHERE uid = ? LIMIT " & $limit & ";"), user):
    result.add(row[0])

proc getAllBookmarks*(db: DbConn, user: string): seq[string] =
  ## Returns a sequence of post IDs that a user has bookmarked.
  ## 
  ## Note: This has NO limit, do not use this please.
  for row in db.getAllRows(sql"SELECT pid FROM bookmarks WHERE uid = ?;", user):
    result.add(row[0])

proc unbookmarkPost*(db: DbConn, user, post: string) =
  db.exec(sql"DELETE FROM bookmarks WHERE uid = ? AND pid = ?;", user, post)
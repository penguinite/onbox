# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
#
# This file is part of Onbox. Specifically, the Quark repository.
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
# onbox/db/sessions.nim:
## This module contains all database logic for handling user sessions.
## Such as verifying them, creating them and also deleting them
## if the user demands it or if they have gone out-of-date.
import users, ../strextra

# From somewhere in the standard library
import std/[times]

# From third-party libraries
import rng, db_connector/db_postgres

proc updateTimestampForSession*(db: DbConn, id: string) = 
  db.exec(sql"UPDATE logins SET last_used = ? WHERE id = ?;", !$(now().utc), id)

proc sessionExists*(db: DbConn, id: string): bool =
  ## Checks if a session exists and returns whether or not it does.
  db.updateTimestampForSession(id)
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM logins WHERE id = ?);", id
  )[0] == "t"

proc createSession*(db: DbConn, user: string, date: DateTime = now().utc): string =
  ## Creates a session for a user and returns it's id
  ## The user parameter should contain a user's id.
  result = randstr(32)
  db.exec(
    sql"INSERT INTO logins VALUES (?, ?, ?);",
    result, user, !$date
  )

proc getSessionUser*(db: DbConn, id: string): string =
  ## Retrieves the user id associated with a session.
  ## The id parameter should contain the session id.
  db.getRow(sql"SELECT uid FROM logins WHERE id = ?;", id)[0]

proc getSessionDate*(db: DbConn, id: string): DateTime =
  ## Retrieves the last use date associated with a session.
  ## The id parameter should contain the session id.
  toDate(db.getRow(sql"SELECT last_used FROM logins WHERE id = ?;", id)[0])

proc sessionExpired*(db: DbConn, id: string): bool =
  ## Checks if a session has expired, meaning that it is 1 week old.
  (now().utc - db.getSessionDate(id) == initDuration(weeks = 1))

proc sessionValid*(db: DbConn, id: string): bool =
  ## Checks if a session is valid.
  ## The id parameter should contain the session id,
  ## The user parameter should contain the user's id.
  ## 
  ##
  ## Use this over sessionExists and sessionEpired
  (db.sessionExists(id) and not db.sessionExpired(id))

proc deleteSession*(db: DbConn, id: string) =
  ## Deletes a session.
  db.exec(sql"DELETE FROM logins WHERE id = ?;", id)

proc deleteAllSessionsForUser*(db: DbConn, user: string) =
  ## Deletes all the sessions that a single user has.
  ## Should be ran after a password change or at user's request
  db.exec(sql"DELETE FROM logins WHERE uid = ?;", user)

proc cleanSessions*(db: DbConn) =
  ## Cleans sessions that have expired or that belong to non-existent users.
  for row in db.getAllRows(sql"SELECT id,uid FROM logins;"):
    if not db.userIdExists(row[1]) or db.sessionExpired(row[0]):
      db.deleteSession(row[0])

proc getTotalSessions*(db: DbConn): int =
  len(db.getAllRows(sql"SELECT 0 FROM logins;"))

proc getTotalValidSessions*(db: DbConn): int =
  for row in db.getAllRows(sql"SELECT id FROM logins;"):
    if not db.sessionExpired(row[0]):
      inc result
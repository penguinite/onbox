# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
# Copyright © penguinite 2024 <penguinite@tuta.io>
#
# This file is part of Pothole. Specifically, the Quark repository.
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
# quark/db/codes.nim:
## This module handles authorization code creation, cleanup and processing.

# From Quark
import quark/private/database
import quark/db/[apps, users]

# From standard library
# From somewhere in the standard library
import std/[tables, strutils, times]

# From elsewhere (third-party libraries)
import rng

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
const authCodesCols*: OrderedTable[string, string] = {"id": "TEXT PRIMARY KEY NOT NULL", # The code itself
"uid": "TEXT NOT NULL", # The user id associated with this code.
"cid": "TEXT NOT NULL", # The client id associated with this code.
"scopes": "TEXT DEFAULT 'read'", # The scopes that were requested
"__A": "foreign key (cid) references apps(id)", # Some foreign key for integrity
"__B": "foreign key (uid) references users(id)", # Some foreign key for integrity
}.toOrderedTable

proc getSpecificAuthCode*(db: DbConn, user, client: string): string =
  ## Returns a specific auth code.
  return db.getRow(sql"SELECT id FROM auth_codes WHERE uid = ? AND cid = ?;", user, client)[0]

proc authCodeExists*(db: DbConn, user, client: string): bool =
  return has(db.getRow(sql"SELECT id FROM auth_codes WHERE uid = ? AND cid = ?;", user, client))

proc authCodeExists*(db: DbConn, id: string): bool =
  return has(db.getRow(sql"SELECT id FROM auth_codes WHERE id = ?;", id))

proc createAuthCode*(db: DbConn, user, client, scopes: string): string =
  ## Creates a code
  if db.authCodeExists(user, client):
    raise newException(DbError, "Code already exists for user \"" & user & "\" and client \"" & client & "\"")

  var id = randstr(32)
  while db.authCodeExists(id):
    id = randstr(32)
  
  db.exec(sql"INSERT INTO auth_codes VALUES (?,?,?,?);", id, user, client, scopes)
  return id

proc codeHasScopes*(db: DbConn, id:string, scopes: seq[string]): bool =
  let appScopes = db.getRow(sql"SELECT scopes FROM auth_codes WHERE id = ?;", id)[0].split(" ")
  result = false

  for scope in scopes:
    for codeScope in appScopes:
      if codeScope == scope or codeScope == scope.returnStartOrScope():
        result = true
        break
  
  return result

proc getScopesFromCode*(db: DbConn, id: string): seq[string] =
  return db.getRow(sql"SELECT scopes FROM auth_codes WHERE id = ?;", id)[0].split(" ")

proc deleteAuthCode*(db: DbConn, id: string) =
  ## Deletes an authentication code
  db.exec("DELETE FROM oauth WHERE code = ?;", id)
  db.exec("DELETE FROM auth_codes WHERE id = ?;", id)

proc getUserFromAuthCode*(db: DbConn, id: string): string =
  ## Returns user id when given auth code
  return db.getRow(sql"SELECT uid FROM auth_codes WHERE id = ?;", id)[0]


proc getAppFromAuthCode*(db: DbConn, id: string): string =
  return db.getRow(sql"SELECT cid FROM auth_codes WHERE id = ?;", id)[0]

proc authCodeValid*(db: DbConn, id: string): bool =
  ## Does some extra checks in addition to authCodeExists()
  if not db.authCodeExists(id):
    return false
  
  # Check if the associated app exists
  if not db.clientExists(
    db.getAppFromAuthCode(id)
  ):
    db.deleteAuthCode(id)
    return false
  
  # Check if the associated user exists
  if not db.userIdExists(
    db.getUserFromAuthCode(id)
  ):
    db.deleteAuthCode(id)
    return false

  if db.getUserFromAuthCode(id) == "null":
    db.deleteAuthCode(id)
    return false

  return true

proc cleanupCodes*(db: DbConn) =
  for row in db.getAllRows(sql"SELECT id FROM auth_codes;"):
    discard db.authCodeValid(row[0])

proc cleanupCodesVerbose*(db: DbConn): seq[(string, string, string)] =
  ## Same as cleanupCodes but it returns a list of all of the codes that were deleted.
  ## Useful for interactive situations such as in potholectl.
  ## The sequences consists of a tulip in the order: Auth Code Id -> User Id -> Client Id
  for row in db.getAllRows(sql"SELECT id,uid,cid FROM auth_codes;"):
    if not db.authCodeValid(row[0]):
      result.add((row[0], row[1], row[2]))
  return result

proc getCodesForUser*(db: DbConn, user_id: string): seq[string] =
  ## Returns all the valid authentication codes associated with a user
  var purge = db.userIdExists(user_id)
  if user_id == "null":
    purge = true
    
  for row in db.getAllRows(sql"SELECT id FROM auth_codes WHERE uid = ?;", user_id):
    if not db.clientExists(db.getAppFromAuthCode(row[0])) or purge:
      db.deleteAuthCode(row[0])
      continue
    result.add row[0]
  return result
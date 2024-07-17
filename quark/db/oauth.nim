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
# quark/db/oauth.nim:
## This module contains all database logic for handling oauth tokens and code generation.

import quark/private/database
import quark/db/[auth_codes, apps]
import quark/[post, strextra]
import rng

# From somewhere in the standard library
import std/[tables, times]

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
const oauthCols*: OrderedTable[string, string] = {"token": "TEXT PRIMARY KEY NOT NULL UNIQUE", # The oauth token
"uses_code": "BOOLEAN DEFAULT 'false'", # The type of token.
"code": "TEXT UNIQUE", # The oauth code that was generated for this tokem
"cid": "TEXT NOT NULL", # The client id of the app that this token belongs to
"last_use": "TIMESTAMP NOT NULL", # Anything older than a week will be cleared out
"__A": "foreign key (code) references auth_codes(id)", # Some foreign key for integrity
"__B": "foreign key (cid) references apps(id)", # Some foreign key for integrity
}.toOrderedTable

proc updateTimestampForOAuth*(db: DbConn, id: string) = 
  if not has(db.getRow(sql"SELECT id FROM oauth WHERE id = ?;", id)):
    return
  db.exec(sql"UPDATE oauth SET last_use = ? WHERE id = ?;", utc(now()).toDbString(), id)

proc purgeOldOauthTokens*(db: DbConn) =
  for row in db.getAllRows(sql"GET id,code,cid,last_use FROM oauth;"):
    if row[2] != "" and not db.authCodeExists(row[2]):
      db.exec(sql"DELETE FROM oauth WHERE id = ?;", row[1])
      continue

    if not db.clientExists(row[3]):
      db.exec(sql"DELETE FROM oauth WHERE id = ?;", row[1])
      continue

    if now().utc - toDateFromDb(row[4]) == initDuration(weeks = 1):
      db.exec(sql"DELETE FROM oauth WHERE id = ?;", row[1])

proc tokenExists*(db: DbConn, id: string): bool =
  db.updateTimestampForOAuth(id)
  return has(db.getRow(sql"SELECT id FROM oauth WHERE id = ?;", id))

proc tokenUsesCode*(db: DbConn, id: string): bool =
  return parseBool(db.getRow(sql"SELECT uses_code FROM oauth WHERE id = ?;", id)[0])

proc createToken*(db: DbConn, cid: string, code: string = ""): string =
  var id = randstr(32)

  while db.tokenExists(id):
    id = randstr(32)

  let uses_code = code != ""

  db.exec(
    sql"INSERT INTO oauth VALUES (?,?,?,?);",
    id, uses_code, code, cid, utc(now()).toDbString()
  )

  return id

proc getTokenCode*(db: DbConn, id: string): string =
  return db.getRow(sql"SELECT code FROM oauth WHERE id = ?;", id)[0]

proc getTokenUser*(db: DbConn, id: string): string =
  return db.getUserFromAuthCode(db.getTokenCode(id))

proc getTokenApp*(db: DbConn, id: string): string =
  return db.getRow(sql"SELECT cid FROM oauth WHERE id = ?;", id)[0]

proc getTokenFromCode*(db: DbConn, code: string): string =
  return db.getRow(sql"SELECT id FROM oauth WHERE code = ?;", code)[0]



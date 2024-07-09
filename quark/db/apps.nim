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
# quark/db/boosts.nim:
## This module contains all database logic for handling boosts.

import ../private/database
import rng

# From somewhere in the standard library
import std/[tables, strutils]

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}
const appsCols*: OrderedTable[string, string] = {"id": "TEXT PRIMARY KEY NOT NULL", # The client Id for the application
"secret": "TEXT NOT NULL", # The client secret for the application
"scopes": "TEXT NOT NULL", # Scopes of this application, space-separated.
"name": "TEXT ", # Name of application
"link": "TEXT" # The homepage or source code link to the application
}.toOrderedTable

# TODO: Finish this and test it

proc createClient*(db: DbConn, name: string, link: string = "", scopes: string = "read"): string =
  var id, secret = randstr()
  # Check if ID already exists first.
  while db.getRow(sql"SELECT name FROM apps WHERE id = ?;", id)[0] != "":
    id = randstr()

  db.exec(sql"INSERT INTO apps VALUES (?,?,?);", id, secret, scopes, name, link)
  return id

proc getClientLink*(db: DbConn, id: string): string = 
  return db.getRow(sql"SELECT link FROM apps WHERE id = ?;", id)[0]

proc getClientName*(db: DbConn, id: string): string = 
  return db.getRow(sql"SELECT name FROM apps WHERE id = ?;", id)[0]

proc getClientSecret*(db: DbConn, id: string): string =
  return db.getRow(sql"SELECT secret FROM apps WHERE id = ?;", id)[0]

proc clientExists*(db: DbConn, id: string): bool = 
  return has(db.getRow(sql"SELECT id FROM apps WHERE id = ?;", id))

proc returnStartOrScope(s: string): string =
  if s.startsWith("read"):
    return "read"
  if s.startsWith("write"):
    return "write"
  if s.startsWith("admin:read"):
    return "admin:read"
  if s.startsWith("admin:write"):
    return "admin:write"
  return s

proc hasScope*(db: DbConn, id:string, scope: string): bool =
  let appScopes = db.getRow(sql"SELECT scopes FROM apps WHERE id = ?;", id)[0].split(" ")
  result = false

  for appScope in appScopes:
    if appScope == scope or appScope == scope.returnStartOrScope():
      result = true
      break
  
  return result

proc verifyScope*(pre_scope: string): bool =
  ## Just verifies if a scope is valid or not.
  if len(pre_scope) < 4 or len(pre_scope) > 34:
    # "read" is the smallest possible scope, so anything less is invalid automatically.
    # "admin:write:canonical_email_blocks" is the largest possible scope, so anything larger is invalid automatically.
    return false

  var scope = pre_scope.toLowerAscii()

  # If there is no colon, then it means
  # it's one of the simpler scopes.
  if ':' notin scope:
    case scope:
    of "read", "write", "push":
      return true
    else:
      return false
  
  # Let's get this out of the way
  # Since the later code does not deal with
  # admin:read and admin:write
  case scope:
  of "admin:read", "admin:write":
    return true
  else:
    discard
  
  var list = scope.split(":")
  if len(list) < 2 or len(list) > 3:
    return false # A scope has usually 2-3 parts of colons. Anything higher is unusual.

  # Parse the first part.
  case list[0]:
  of "read":
    if len(list) != 2:
      return false # A read scope only has 2 parts.

    return list[1] in @["accounts", "blocks", "bookmarks", "favorites", "favourites", "filters", "follows", "lists", "mutes", "notifications", "search", "statuses"]
  of "write":
    if len(list) != 2:
      return false # A write scope only has 2 parts.
    return list[1] in @["accounts", "blocks", "bookmarks", "conversations", "favorites", "favourites", "filters", "follows", "lists", "media", "mutes", "notifications", "reports", "statuses"]
  of "admin":
    if len(list) != 3:
      return false # An admin scope only has 3 parts.

    case list[1]:
    of "read":
      return list[2] in @["accounts", "reports", "domain_allows", "domain_blocks", "ip_blocks", "email_domain_blocks", "canonical_domain_blocks"]
    of "write":
      return list[2] in @["accounts", "reports", "domain_allows", "domain_blocks", "ip_blocks", "email_domain_blocks", "canonical_domain_blocks"]
    else:
      return false
  else:
    return false
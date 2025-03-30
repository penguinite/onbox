# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
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
# db/oauth.nim:
## This module contains all database logic for handling oauth tokens.

# From Pothole
import ../strextra

# From third-party libraries
import rng, db_connector/db_postgres

proc tokenExists*(db: DbConn, id: string): bool =
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM oauth_tokens WHERE id = ?);", id
  )[0] == "t"

proc createToken*(db: DbConn, client, user: string, scopes: openArray[string]): string =
  result = randstr(32)
  db.exec(
    sql"INSERT INTO oauth_tokens VALUES (?,?,?,?);",
    result, client, user, !$scopes
  )

proc getTokenUser*(db: DbConn, id: string): string =
  ## Returns ID of the user associated with a token.
  ## If this is empty, then there is no user associated with a token
  db.getRow(sql"SELECT uid FROM oauth_tokens WHERE id = ?;", id)[0]

proc getTokenApp*(db: DbConn, id: string): string =
  ## Returns ID of the app associated with a token.
  ## If this is empty, then there is no app associated with this token
  ## (heartbreaking, I know.)
  db.getRow(sql"SELECT cid FROM oauth_tokens WHERE id = ?;", id)[0]

proc getTokenScopes*(db: DbConn, id: string): seq[string] =
  ## Returns the list of scopes that a token has access to.
  ## Use this for verifying permissions requested by a token app client.
  toStrSeq(db.getRow(sql"SELECT scopes FROM oauth_tokens WHERE id = ?;", id)[0])

proc deleteOAuthToken*(db: DbConn, id: string) =
  ## Deletes an oauth token from the db. Forcing the app to regenerate it.
  db.exec(sql"DELETE FROM oauth_tokens WHERE id = ?;", id)

# TODO: Consider implement a "last_used" attribute
# to clean up old oauth tokens.
# Or, maybe we could consider oauth tokens to be the same as apps.
# Which is to say, they last forever.
# But also, we *could* delete them...
# We could just delete them every month or so, and have apps regenerate them.
# or provide a potholectl command to delete oauth tokens
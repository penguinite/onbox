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
# api/accounts.nim:
## This module contains all the routes for the accounts method in the mastodon api.

# From somewhere in Quark
import quark/user

# From somewhere in Pothole
import pothole/[routeutils, database]

# From somewhere in the standard library
import std/json

# From nimble/other sources
import mummy

proc accountsVerifyCredentials*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  if not req.authHeaderExists():
    respJsonError("The access token is invalid")
  
  let token = req.getAuthHeader()
  var user: User

  dbPool.withConnection db:
    # Check if token actually exists
    if not db.tokenExists(token):
      respJsonError("The access token is invalid")
    
    # Check if token is assigned to a user
    if not db.tokenUsesCode(token):
      respJsonError("This method requires an authenticated user", 422)
    
    # Get the user's id.
    user = db.getUserById(db.getTokenUser(token))
  

  var result = %* {
    "name": "TODO",
    "website": "TODO",
  }
  req.respond(200, headers, $(result))
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
import quark/strextra

# From somewhere in Pothole
import pothole/[routeutils, database, conf]
import pothole/private/apientities

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
  var result: JsonNode

  dbPool.withConnection db:
    # Check if token actually exists
    if not db.tokenExists(token):
      respJsonError("The access token is invalid")
    
    # Check if token is assigned to a user
    if not db.tokenUsesCode(token):
      respJsonError("This method requires an authenticated user", 422)
    result = credentialAccount(db.getTokenUser(token))
  req.respond(200, headers, $(result))

proc accountsGet*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  if not req.pathParams.contains("id"):
    respJsonError("Missing ID parameter")
  
  if req.pathParams["id"].isEmptyOrWhitespace():
    respJsonError("Invalid account id.")
  
  configPool.withConnection config:
    # If the instance has whitelist mode
    # Then check the oauth token.
    if config.getBoolOrDefault("web", "whitelist_mode", false):
      if not req.authHeaderExists():
        respJsonError("This API requires an authenticated user", 401)
      
      let token = req.getAuthHeader()
      dbPool.withConnection db:
        # Check if the token exists in the db
        if not db.tokenExists(token):
          respJsonError("This API requires an authenticated user", 401)
        
        # Check if the token has a user attached
        if not db.tokenUsesCode(token):
          respJsonError("This API requires an authenticated user", 401)
        
        # Double-check the auth code used.
        if not db.authCodeValid(db.getTokenCode(token)):
          respJsonError("This API requires an authenticated user", 401)
        
        # Check if the client registered to the token
        # has a public oauth scope.
        if not db.hasScope(db.getTokenApp(token), "read:accounts"):
          respJsonError("This API requires an authenticated user", 401)

  var result: JsonNode  
  dbPool.withConnection db:
    if not db.userIdExists(req.pathParams["id"]):
      respJsonError("Record not found", 404)
    result = account(req.pathParams["id"])

    # TODO: When support for ActivityPub is added...
    # Hopefully... then implement support for remote users.
    # See the Mastodon API docs.

    if db.userFrozen(req.pathParams["id"]):
      result["suspended"] = newJBool(true)
    
  req.respond(200, headers, $(result))
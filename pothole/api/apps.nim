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
# api/ph.nim:
## This module contains all the routes for the ph method in the api

# From somewhere in Pothole
import pothole/[database, routeutils]

# From somewhere in the standard library
import std/[json, strutils]

# From nimble/other sources
import mummy


proc v1AppsMultipart*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  var result: JsonNode

  # First, Check if client_name and redirect_uris exist.
  # If not, then error out.
  let mp = req.unrollMultipart()
  if not mp.isValidFormParam("client_name") or not mp.isValidFormParam("redirect_uris"):
    req.respond(401, headers, $(%*{"error": "Missing required parameters."}))
    return

  var website = ""
  if mp.isValidFormParam("website"):
    website = mp.getFormParam("website")
  
  var
    client_name = mp.getFormParam("client_name")
    redirect_uris = mp.getFormParam("redirect_uris") # TODO: What does one do with this???

  # Parse scopes
  var scopes = "read"
  if mp.isValidFormParam("scopes"):
    for scope in mp.getFormParam("scopes").split(" "):
      if not scope.verifyScope():
        req.respond(401, headers, $(%*{"error": "Invalid scope: " & escape(scope)}))
        return
    scopes = mp.getFormParam("scopes")
  
  var client_id, client_secret: string
  dbPool.withConnection db:
    client_id = db.createClient(
      client_name,
      website,
      scopes
    )
    client_secret = db.getClientSecret(client_id)
  
  result = %* {
    "id": client_id,
    "name": client_name,
    "website": website,
    "redirect_uri": redirect_uris,
    "client_id": client_id,
    "client_secret": client_secret,
    "scopes": scopes.split(" ") # Undocumented.
  }


  req.respond(200, headers, $(result))

proc v1AppsVerify*(req: Request) = 
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  var result = %* {}
  req.respond(200, headers, $(result))
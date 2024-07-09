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

  var
    result: JsonNode

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
    # TODO: What does one do with this???
    # The API docs suggest that we should parse and see if its an absolute uri.
    # Throwing an error if it isn't... But like, what's the point of this anyway???
    redirect_uris = mp.getFormParam("redirect_uris") 

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

proc hasValidStrKey(j: JsonNode, k: string): bool =
  if not j.hasKey(k):
    return false

  if j[k].kind != JString:
    return false

  try:
    if j[k].getStr().isEmptyOrWhitespace():
      return false
  except:
    return false

  return true


proc v1AppsJSON*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  var json: JsonNode = newJNull()
  try:
    json = parseJSON(req.body)
  except:
    req.respond(401, headers, $(%*{"error": "Invalid JSON."}))
    return

  # Double check if the parsed JSON is *actually* valid.
  if json.kind == JNull:
    req.respond(401, headers, $(%*{"error": "Invalid JSON."}))
    return

  # First, Check if client_name and redirect_uris exist.
  # If not, then error out.

  if not json.hasValidStrKey("client_name") or not json.hasValidStrKey("redirect_uris"):
    req.respond(401, headers, $(%*{"error": "Missing required parameters."}))
    return

  var website = ""
  if json.hasValidStrKey("website"):
    website = json["website"].getStr()
  
  var
    client_name = json["client_name"].getStr()
    # TODO: What does one do with this???
    # The API docs suggest that we should parse and see if its an absolute uri.
    # Throwing an error if it isn't... But like, what's the point of this anyway???
    redirect_uris = json["redirect_uris"].getStr()

  # Parse scopes
  var scopes = "read"
  if json.hasValidStrKey("scopes"):
    for scope in json["scopes"].getStr().split(" "):
      if not scope.verifyScope():
        req.respond(401, headers, $(%*{"error": "Invalid scope: " & escape(scope)}))
        return
    scopes = json["scopes"].getStr()
  
  var client_id, client_secret: string
  dbPool.withConnection db:
    client_id = db.createClient(
      client_name,
      website,
      scopes
    )
    client_secret = db.getClientSecret(client_id)
  
  var result = %* {
    "id": client_id,
    "name": client_name,
    "website": website,
    "redirect_uri": redirect_uris,
    "client_id": client_id,
    "client_secret": client_secret,
    "scopes": scopes.split(" ") # Undocumented.
  }

  req.respond(200, headers, $(result))

proc v1Apps*(req: Request) =
  # Switch between multipart and JSON 
  # if req.unrollMultipart() fails.
  try:
    discard req.unrollMultipart()
    # If we are still here then it means the 
    # request uses multipart.
    req.v1AppsMultipart()
  except:
    req.v1AppsJSON()

  
proc v1AppsVerify*(req: Request) = 
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  var result = %* {}
  req.respond(200, headers, $(result))
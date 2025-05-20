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
# onbox/api/apps.nim:
## This module contains all the routes for the apps method in the mastodon api

# From somewhere in Quark
import onbox/routes

# From somewhere in the standard library
import std/[json, strutils]

# From nimble/other sources
import mummy, waterpark/postgres,
       amicus/[apps, oauth]

proc v1Apps*(req: Request) =
  # This is more complex than what I would have preferred...
  # TODO: A possible refactor is due here.

  var json: JsonNode
  try: json = req.fetchReqBody() 
  except: return

  # Check if the required stuff is there
  if not json.hasValidStrKey("client_name") or not json.hasValidStrKey("redirect_uris"):
    respJsonError("Missing required parameters.")

  # Parse scopes
  # A client may supply a single string
  # which we have to split
  # Or it may supply a string JArray object
  # 
  # We have to handle both.
  var scopes = @["read"]
  if json.hasKey("scopes"):
    case json["scopes"].kind:
    of JString: scopes = json["scopes"].getStr("read").split(" ")
    of JArray:
      # A bit ugly, but it'll do.
      # It'd be nice if std/json provided an equivalent to iniplus's getStringArray()
      # That way, we wouldn't need to do this sorta thing for code cleanliness.
      for scope in json["scopes"].getElems(@[newJString("read")]):
        scopes.add(scope.getStr())
    else: respJsonError("Unknown scopes JKind")
  
  for scope in scopes:
    if not scopeValid(scope):
      respJsonError("Invalid scope: " & scope)

  var client_id, client_secret: string
  dbPool.withConnection db:
    (client_id, client_secret) = db.createClient(
      json["client_name"].getStr(),
      json["website"].getStr(""),
      scopes,
      [json["redirect_uris"].getStr()] # TODO: Make this into an array like scopes.
    )
  
  req.respond(
    200,
    createHeaders("application/json"), $(%* {
      "id": client_id,
      "name": json["client_name"].getStr(),
      "website": json["website"].getStr(""),
      "redirect_uri": [json["redirect_uris"].getStr()],
      "client_id": client_id,
      "client_secret": client_secret,
      "scopes": scopes # Non-standard: Undocumented.
    })
  )
  
proc v1AppsVerify*(req: Request) = 
  var token = ""
  try: token = req.verifyClientExists()
  except: return

  dbPool.withConnection db:
    let id = db.getTokenApp(token)
    req.respond(200, createHeaders("application/json"),
      $(%*
        {
          "name": db.getClientName(id),
          "website": db.getClientLink(id)
        }
      )
    )

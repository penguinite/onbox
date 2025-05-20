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
# onbox/api/accounts.nim:
## This module contains all the routes for the accounts method in the mastodon api.

# From Onbox
import onbox/[conf, routes, entities]

# From somewhere in the standard library
import std/[json, strutils]

# From nimble/other sources
import mummy, iniplus,
       waterpark, waterpark/postgres,
       amicus/[oauth, apps, users]

proc accountsVerifyCredentials*(req: Request) =
  var token, user = ""
  try:
    token = req.verifyClientExists()
    user = req.verifyClientUser(token)
  except: return

  dbPool.withConnection db:
    # We need to run our own scope checks since our
    # situation is more complex than just a single scope
    if not db.tokenHasScope(token, "read:account") and not db.hasScope(token, "profile"):
      respJsonError("This method requires an authenticated user", 422)
  
  dbPool.withConnection db:
    configPool.withConnection config:
      req.respond(
        200,
        createHeaders("application/json"),
        $(credentialAccount(db, config, user))
      )

proc accountsGet*(req: Request) =
  # Run some basic input checks first.
  if not req.pathParams.contains("id") or req.pathParams["id"].isEmptyOrWhitespace():
    respJsonError("Invalid ID parameter")
  
  configPool.withConnection config:
    # If the instance is in lockdown mode
    # Then check the oauth token.
    if config.getBoolOrDefault("web", "lockdown_mode", false):
      try:
        # Check that the client has an authenticated user bound to it.
        discard req.verifyClientUser(
          req.verifyClientExists()
        )
      except: return

  dbPool.withConnection db:
    if not db.userIdExists(req.pathParams["id"]):
      respJsonError("Record not found", 404)
    
    # TODO: When support for ActivityPub is added...
    # Hopefully... then implement support for remote users.
    # See the Mastodon API docs.
    configPool.withConnection config:
      req.respond(200, createHeaders("application/json"), $(account(db, config, req.pathParams["id"])))
    

proc accountsGetMultiple*(req: Request) =
  if not req.queryParams.contains("id[]"):
    respJsonError("Missing account ID query parameter.")

  var ids: seq[string] = @[]
  for query in req.queryParams:
    if query[0] == "id[]" and not query[1].isEmptyOrWhitespace():
      ids.add(query[1])
      
  configPool.withConnection config:
    # If the instance is in lockdown mode
    # Then check the oauth token.
    if config.getBoolOrDefault("web", "lockdown_mode", false):
      try:
        # Check that the client has an authenticated user bound to it.
        discard req.verifyClientUser(
          req.verifyClientExists()
        )
      except: return

  var result = newJArray()

  configPool.withConnection config:
    dbPool.withConnection db:
      for id in ids:
        # TODO: When support for ActivityPub is added...
        # Hopefully... then implement support for remote users.
        # See the Mastodon API docs.
        if db.userIdExists(id):
          result.elems.add(account(db, config, id))
  req.respond(200, createHeaders("application/json"), $(result))

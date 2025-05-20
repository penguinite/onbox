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
# onbox/api/oauth.nim:
## This module contains all the routes for the oauth method in the api

# From somewhere in Onbox
import onbox/[routes, entities]

# From somewhere in the standard library
import std/[json, strutils]

# From nimble/other sources
import mummy, waterpark/postgres,
       amicus/tag

proc followedTags*(req: Request) =
  # TODO: Implement pagination *properly*
  # If any of these are present, then just error out.
  for i in @["max_id", "since_id", "min_id"]:
    if req.queryParamExists(i):
      respJson("You're using a pagination feature and I honest to goodness WILL NOT IMPLEMENT IT NOW", 500)
  
  # Same thing for the Link http header
  if req.headers.contains("Link"):
    respJson("You're using a pagination feature and I honest to goodness WILL NOT IMPLEMENT IT NOW", 500)
    
  var token, user =""
  try:
    token = req.verifyClientExists()
    req.verifyClientScope(token, "read:follows")
    user = req.verifyClientUser(token)
  except: return

  var result = newJArray()
  
  # Parse ?limit=x
  # If ?limit isn't present then default to 100
  var limit = 100

  if req.queryParams.contains("limit"):
    try: limit = parseInt(req.queryParams["limit"])
    except: limit = 100
  
  if limit > 200:
    # MastoAPI docs sets a limit of 200.
    # So we will throw an error if it is over 200.
    respJsonError("Limit cannot be over 200", 401)

  dbPool.withConnection db:
    for tag in db.getTagFollows(user, limit):
      result.elems.add(tag(db, tag, user))
  req.respond(200, createHeaders("application/json"), $(result))

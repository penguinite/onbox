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
# onbox/api/bookmarks.nim:
## This module contains all the routes for the bookmarks method in the mastodon api.

# From somewhere in Onbox
import onbox/[conf, entities, routes]

# From somewhere in the standard library
import std/[json, strutils]

# From nimble/other sources
import mummy, waterpark/postgres,
       amicus/bookmarks

proc bookmarksGet*(req: Request) =
  var token, user = ""
  try:
    token = req.verifyClientExists()
    req.verifyClientScope(token, "read:bookmarks")
    user = req.verifyClientUser(token)
  except: return

  var
    limit = 20
    result: JsonNode = newJArray()
  
  if req.queryParams.contains("limit"):
    try: limit = parseInt(req.queryParams["limit"])
    except: limit = 20

  ## TODO: Implement pagination with min_id, max_id and since_id
  dbPool.withConnection db:
    configPool.withConnection config:
      for id in db.getBookmarks(user, limit):
        result.elems.add(status(db, config, id))

  req.respond(200, createHeaders("application/json"), $(result))

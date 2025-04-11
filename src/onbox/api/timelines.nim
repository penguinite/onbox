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
# api/oauth.nim:
## This module contains all the routes for the oauth method in the api

# From somewhere in Quark
import onbox/db/timelines
import onbox/[conf, routes, entities]

# From somewhere in the standard library
import std/[json, strutils]

# From nimble/other sources
import mummy, waterpark/postgres, iniplus

proc timelinesPublic*(req: Request) =
  # TODO: This implementation lacks the following:
  #     - only_media query support (No media support yet, so this isn't implemented)
  #     - max_id, since_id, min_id or any form of pagination.
  # Limit access to authenticated clients if lockdown mode is enabled
  configPool.withConnection config:
    if config.getBoolOrDefault("web", "lockdown_mode", false):
      try:
        var token = req.verifyClientExists()
        req.verifyClientScope(token, "read:statuses")
      except: return
    
  var
    local = false
    remote = false
    limit = 20
  
  if req.queryParamExists("local"):
    local = parseBool(req.queryParams["local"])
  if req.queryParamExists("remote"):
    remote = parseBool(req.queryParams["remote"])
  if req.queryParamExists("limit"):
    limit = parseInt(req.queryParams["limit"])
  
  if limit > 40:
    respJsonError("Limit cannot be over 40", 401)
  
  if local and remote:
    respJsonError("Remote and local can't both be set to true", 401)


  configPool.withConnection config:
    var result = newJArray()
    dbPool.withConnection db:
      for id in db.getPublicTimeline(local, remote, limit):
        result.add(status(db, config, id))
    req.respond(200, createHeaders("application/json"), $(result))



proc timelinesHome*(req: Request) =
  # TODO: This implementation lacks the following:
  #     - max_id, since_id, min_id or any form of pagination.
  # If any of these are present, then just error out.
  for i in @["max_id", "since_id", "min_id"]:
    if req.queryParamExists(i):
      respJson("You're using a pagination feature and I honest to goodness WILL NOT IMPLEMENT IT NOW", 500)
  
  # Now we can begin actually implementing the API
  
  # Parse ?limit=x
  # If ?limit isn't present then default to 20 posts
  var limit = 20

  if req.queryParamExists("limit"):
    limit = parseInt(req.queryParams["limit"])

  if limit > 40:
    # MastoAPI docs sets a limit of 40.
    # So we will throw an error if it is over 40
    respJsonError("Limit cannot be over 40", 401)

  var token, user = ""
  try:
    token = req.verifyClientExists()
    req.verifyClientScope(token, "read:statuses")
    user = req.verifyClientUser(token)
  except: return

  var result = newJArray()
  dbPool.withConnection db:
    configPool.withConnection config:
      for postId in db.getHomeTimeline(user, limit):
        result.elems.add(status(db, config, postId))
  req.respond(200, createHeaders("application/json"), $(result))



proc timelinesHashtag*(req: Request) =
  # TODO: Implement pagination *properly* and tag searching
  # If any of these are present, then just error out.

  for i in @["max_id", "since_id", "min_id", "any", "all", "none"]:
    if req.queryParamExists(i):
      respJson("You're using an unsupported feature and I honest to goodness WILL NOT IMPLEMENT IT NOW", 500)
  
  # These booleans control which types of post to show
  # Fx. if local is disabled then we won't include local posts
  # if remote is disabled then we won't include remote posts
  # if both are enabled (the default) then we will include all types of post.
  var local, remote = true

  # The mastodon API has 2 query parameters for this API endpoint
  # local, which when set to true, tells the server to include only local posts
  # and remote which does the same as local but with remote posts instead.
  # Both are set to false...
  if req.queryParamExists("local"):
    local = parseBool(req.queryParams["local"])
    remote = not parseBool(req.queryParams["local"])

  if req.queryParamExists("remote"):
    remote = parseBool(req.queryParams["remote"])
    local = not parseBool(req.queryParams["remote"])
  
  # TODO: Implement the "only_media" query parameter for this API endpoint.
  # We dont have media handling yet and so we can't test it.
  #var onlyMedia = false

  # If ?limit isn't present then default to 20 posts
  var limit = 20
  if req.queryParamExists("limit"):
    limit = parseInt(req.queryParams["limit"])

  # MastoAPI docs sets a limit of 40.
  # So we will throw an error if it is over 40
  if limit > 40:
    respJsonError("Limit cannot be over 40", 401)

  var result = newJArray()
  configPool.withConnection config:
    if config.getBoolOrDefault("web", "lockdown_mode", false):
      try:
        req.verifyClientScope(req.verifyClientExists(), "read:statuses")
      except: return

    dbPool.withConnection db:
        for postId in db.getTagTimeline(req.pathParams["tag"], limit, local, remote):
          result.elems.add(status(db, config, postId))
  req.respond(200, createHeaders("application/json"), $(result))

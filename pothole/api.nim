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
# api.nim:
## This module contains routing code for the MastoAPI compatability layer.


# From somewhere in Quark
#import quark/[user, post]

# From somewhere in Pothole
import conf, database, routeutils, lib

# From somewhere in the standard library
import std/[tables, json]

# From nimble/other sources
import mummy

proc v1InstanceView*(req: Request) = 
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  var userCount, postCount, domainCount: int
    
  dbPool.withConnection db:
    userCount = db.getTotalLocalUsers()
    postCount = db.getTotalPosts()
    domainCount = db.getTotalDomains()

  configPool.withConnection config:
    req.respond(200, headers, $(%*
      {
        "uri": config.getString("instance","uri"),
        "title": config.getString("instance","name"),
        "short_description": config.getString("instance", "summary"),
        "description": config.getStringOrDefault(
          "instance", "description",
          config.getString("instance","summary")
        ),
        "email": config.getStringOrDefault("instance","email",""),
        "version": lib.phVersion,
        "urls": {
          "streaming_api": "wss://" & config.getString("instance","uri")
        },
        "stats": {
          "use_count": userCount,
          "status_count": postCount,
          "domain_count": domainCount
        },
        "thumbnail": config.getStringOrDefault("instance", "logo", ""),
        "languages": config.getStringArrayOrDefault("instance", "languages", @["en"]),
        "registrations": config.getBoolOrDefault("user", "registrations_open", true),
        "approval_required": config.getBoolOrDefault("user", "require_approval", false),
        "configuration": {
          "statuses": {
            "max_characters": config.getIntOrDefault("instance", "max_chars", 2000),
            "max_media_attachments": config.getIntOrDefault("instance", "max_attachments", 8),
            "characters_reserved_per_url": 23
          },
        }
      }
    ))
  ## TODO: WIP, https://docs.joinmastodon.org/entities/V1_Instance

proc v2InstanceView*(req: Request) = 
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

const apiRoutes* =  {
  # URLRoute : (HttpMethod, RouteProcedure)
  # /api/ is already inserted before every URLRoute
  "v1/instance": ("GET", v1InstanceView),
  "v2/instance": ("GET", v2InstanceView),
}.toTable
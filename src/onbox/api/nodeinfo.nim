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
# onbox/api/nodeinfo.nim:
## This module contains all the routes that handle stuff related to the nodeinfo standard.

# From somewhere in Onbox
import onbox/[shared, conf, routes]

# From somewhere in the standard library
import std/json

# From nimble/other sources
import mummy, iniplus, waterpark/postgres,
       amicus/[users, sessions, posts]

proc resolveNodeinfo*(req: Request) =
  configPool.withConnection cnf:
    respJson(
      $(%*{
        "links": [
          {
            "href": realURL(cnf) & "2.0",
            "rel":"http://nodeinfo.diaspora.software/ns/schema/2.0"
          }
        ]
      })
    )

proc nodeInfo2x0*(req: Request) =
  dbPool.withConnection db:
    configPool.withConnection config:
      var protocols: seq[string] = @[]
      if config.getBoolOrDefault("instance", "federated", true):
        protocols.add("activitypub")

      respJson(
        $(%* {
          "version": "2.0",
          "software": {
            "name": "Onbox",
            "version": version,
          },
          "protocols": protocols,
          "services": {
            "inbound": [],
            "outbound": [],
          },
          "openRegistrations": config.getBoolOrDefault("user", "registrations_open", true),
          "usage": {
            "totalPosts": db.getNumTotalPosts(),
            "users": {
              "activeHalfYear": db.getNumSessions(),
              "activeMonth": db.getNumValidSessions(),
              "total": db.getTotalLocalUsers()
            }
          },
          "metadata": {
            "nodeName": config.getString("instance", "uri"),
            "nodeDescription": config.getStringOrDefault("instance", "description", config.getStringOrDefault("instance", "summary", "")),
            "accountActivationRequired": config.getBoolOrDefault("user", "require_approval", false),
            "features": [
              "mastodon_api",
              "mastodon_api_streaming",
            ],
            "postFormats":[
              "text/plain",
              "text/html",
              "text/markdown",
              "text/x-rst"
            ],
          }
        })
      )

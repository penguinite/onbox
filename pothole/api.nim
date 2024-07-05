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
import quark/[user, post]

# From somewhere in Pothole
import conf, database, routeutils, lib, assets

# From somewhere in the standard library
import std/[tables, json]

# From nimble/other sources
import mummy

proc v1InstanceView*(req: Request) = 
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  var
    userCount, postCount, domainCount, totalPostsAdmin, followers, following: int
    adminAccount: User
    
  dbPool.withConnection db:
    # The database (unlike the config file or templating object) is
    # a limited resource, so let's use it and quickly give it back.    
    userCount = db.getTotalLocalUsers()
    postCount = db.getTotalPosts()
    domainCount = db.getTotalDomains()
    adminAccount = db.getFirstAdmin()
    totalPostsAdmin = db.getTotalPostsByUserId(adminAccount.id)
    followers = db.getFollowersCount(adminAccount.id)
    following = db.getFollowingCount(adminAccount.id)
    

  var result: JsonNode
  configPool.withConnection config:
    result = %*
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
            "max_media_attachments": config.getIntOrDefault("user", "max_attachments", 8),
            "characters_reserved_per_url": 23
          },
          "media_attachments": {
            "supported_mime_types":["image/jpeg","image/png","image/gif","image/webp","video/webm","video/mp4","video/quicktime","video/ogg","audio/wave","audio/wav","audio/x-wav","audio/x-pn-wave","audio/vnd.wave","audio/ogg","audio/vorbis","audio/mpeg","audio/mp3","audio/webm","audio/flac","audio/aac","audio/m4a","audio/x-m4a","audio/mp4","audio/3gpp","video/x-ms-asf"],
            "image_size_limit": config.getIntOrDefault("storage","upload_size_limit", 10) * 1000000,
            "image_matrix_limit": 16777216, # I copied this as-is from the documentation cause I will NOT be writing code to deal with media file width and height.
            "video_size_limit": config.getIntOrDefault("storage","upload_size_limit", 10) * 1000000,
            "video_frame_rate_limit": 60, # I also won't be writing code to check for video framerates
            "video_matrix_limit": 2304000 # I copied this as-is from the documentation cause I will NOT be writing code to deal with media file width and height.
          },
          "polls": {
            "max_options": config.getIntOrDefault("instance", "max_poll_options", 20),
            "max_characters_per_option": 100,
            "min_expiration": 300,
            "max_expiration": 2629746
          },
          "contact_account": {
            "id": adminAccount.id,
            "username": adminAccount.handle,
            "acct": adminAccount.handle,
            "display_name": adminAccount.name,
            "locked": adminAccount.is_frozen,
            "bot": isBot(adminAccount.kind),
            "discoverable": adminAccount.discoverable,
            "group": isGroup(adminAccount.kind),
            "created_at": "", # TODO: Add to DB
            "note": adminAccount.bio,
            "avatar": config.getAvatar(adminAccount.id),
            "avatar_static": config.getAvatar(adminAccount.id),
            "header": config.getHeader(adminAccount.id),
            "header_static": config.getHeader(adminAccount.id),
            "followers_count": followers,
            "following_count": following,
            "statuses_count": totalPostsAdmin,
            "last_status_at": "", # Tell me, who the hell is using this?!? WHAT FOR?!?
            "emojis": [],
            "fields": [] # TODO: Implement
          }
        }
      }
  
  req.respond(200, headers, $(result))
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
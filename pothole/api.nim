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
import quark/[user, post, crypto]

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
    adminAccountExists: bool
    userCount, postCount, domainCount, totalPostsAdmin, followers, following: int
    fieldsDb: seq[(string, string, bool, DateTime)]
    adminAccount: User
  
  dbPool.withConnection db:
    adminAccountExists = db.adminAccountExists()

  if adminAccountExists:
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
      fieldsDb = db.getFields(adminAccount.id)
  
  # Handle profile fields
  # I yearn for the day when I can get rid of this or replace it with something better
  var fields: seq[JsonNode] = @[]
  for key, value, verified, verified_date in fieldsDb.items:
    var jason = %* {
      "name": key,
      "value": value,
    }
      
    if verified:
      jason["verified_at"] = newJString(verified_date.format("yyyy-mm-dd") & "T" & verified_date.format("hh:mm:ss"))
    else:
      jason["verified_at"] = newJNull()
    
    fields.add(jason)

  var result: JsonNode
  configPool.withConnection config:
    # Specs tell us to either keep "contact_account" null or to fill it with a staff member's details.
    var contact_account = newJNull()
    
    if adminAccountExists:
      contact_account = %* {
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
        "emojis": [], # TODO: I am not sure what this is supposed to be
        "fields": fields
      }

    # Handle instance rules
    var
      rules: seq[JsonNode] = @[]
      i = 0
    for rule in config.getStringArrayOrDefault("instance", "rules", @[]):
      inc(i)
      rules.add(
        %* {
          "id": $i,
          "text": rule
        }
      )
    
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
            "max_characters": config.getIntOrDefault("user", "max_chars", 2000),
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
        },
        "contact_account": contact_account,
        "rules": rules
      }
  
  req.respond(200, headers, $(result))

proc v2InstanceView*(req: Request) = 
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  var
    totalUsers: int
    adminAccountExists: bool
  
  dbPool.withConnection db:
    totalUsers = db.getTotalLocalUsers()
    adminAccountExists = db.adminAccountExists()
  
  var admin_account = newJNull()
  if adminAccountExists:
    # Vars initialized through database:
    var
      followers, following, totalPostsAdmin: int
      admin: User
      fieldsDb: seq[(string, string, bool, DateTime)]

    dbPool.withConnection db:
      admin = db.getFirstAdmin()
      followers = db.getFollowersCount(admin.id)
      following = db.getFollowingCount(admin.id)
      totalPostsAdmin = db.getTotalPostsByUserId(admin.id)

    # Vars initialized through config:
    var avatar, header: string
    configPool.withConnection config:
      avatar = config.getAvatar(admin.id)
      header = config.getHeader(admin.id)
    
    # Initialize profile fields
    var fields: seq[JsonNode] = @[]
    for key, value, verified, verified_date in fieldsDb.items:
      var jason = %* {
        "name": key,
        "value": value,
      }
      
      if verified:
        jason["verified_at"] = newJString(verified_date.format("yyyy-mm-dd") & "T" & verified_date.format("hh:mm:ss"))
      else:
        jason["verified_at"] = newJNull()

      fields.add(jason)

    admin_account = %* {
      "id": admin.id,
      "username": admin.handle,
      "acct": admin.handle,
      "display_name": admin.name,
      "locked": admin.is_frozen,
      "bot": isBot(admin.kind),
      "group": isGroup(admin.kind),
      "discoverable": admin.discoverable,
      "created_at": "", # TODO: Implement
      "note": admin.bio,
      "url": "",
      "avatar": avatar, # TODO for these 4 media related options: Separate static and animated media.
      "avatar_static": avatar,
      "header": header, 
      "header_static": header,
      "followers_count": followers,
      "following_count": following,
      "statuses_count": totalPostsAdmin,
      "last_status_at": "", # Tell me, who the hell is using this?!? WHAT FOR?!?
      "emojis": [], # TODO: I am not sure what this is supposed to be
      "fields": fields
    }

  var result: JsonNode
  configPool.withConnection config:
    # Handle instance rules
    var
      rules: seq[JsonNode] = @[]
      i = 0
    for rule in config.getStringArrayOrDefault("instance", "rules", @[]):
      inc(i)
      rules.add(
        %* {
          "id": $i,
          "text": rule
        }
      )

    result = %*
      {
        "domain": config.getString("instance","uri"),
        "title": config.getString("instance","name"),
        "version": lib.phVersion,
        "source_url": lib.phSourceUrl,
        "description": config.getStringOrDefault(
          "instance", "description",
          config.getString("instance","summary")
        ),
        "usage": {
          "users": {
            "active_month": totalUsers # I am not sure what Mastodon considers "active" to be, but "registered" is good enough for me.
          }
        },
        "thumbail": {
          # The example has blurhash and multiple versions of an image for high-dpi screens.
          # Those are marked optional, so I won't bother implementing them.
          "url": config.getStringOrDefault("instance", "logo", "")
        },
        "languages": config.getStringArrayOrDefault("instance", "languages", @["en"]),
        "configuration": {
          "urls": {
            "streaming_api": "wss://" & config.getString("instance","uri")
          },
          "vapid": {
            "public_key": "" # TODO: Implement vapid keys
          },
          "accounts": {
            "max_featured_tags": config.getIntOrDefault("user","max_featured_tags",10),
            "max_pinned_statuses": config.getIntOrDefault("user","max_pins", 20),
          },
          "statuses": {
            "max_characters": config.getIntOrDefault("user", "max_chars", 2000),
            "max_media_attachments": config.getIntOrDefault("user", "max_attachments", 8),
            "characters_reserved_per_url": 23
          },
          "media_attachments": {
            "supported_mime_types": ["image/jpeg", "image/png", "image/gif", "image/heic", "image/heif", "image/webp", "video/webm", "video/mp4", "video/quicktime", "video/ogg", "audio/wave", "audio/wav", "audio/x-wav", "audio/x-pn-wave", "audio/vnd.wave", "audio/ogg", "audio/vorbis", "audio/mpeg", "audio/mp3", "audio/webm", "audio/flac", "audio/aac", "audio/m4a", "audio/x-m4a", "audio/mp4", "audio/3gpp", "video/x-ms-asf"],
            "image_size_limit": config.getIntOrDefault("storage","upload_size_limit", 10) * 1000000,
            "image_matrix_limit": 16777216,
            "video_size_limit": 41943040,
            "video_frame_rate_limit": 60,
            "video_matrix_limit": config.getIntOrDefault("storage","upload_size_limit", 10) * 1000000,
          },
          "polls": {
            "max_options": config.getIntOrDefault("instance", "max_poll_options", 20),
            "max_characters_per_option": 100,
            "min_expiration": 300,
            "max_expiration": 2629746
          },
          "translation": {
            "enabled": false, # TODO: Switch to on once translation is enabled.
          }
        },
        "registrations": {
          "enabled": config.getBoolOrDefault("user", "registrations_open", true),
          "approval_required": config.getBoolOrDefault("user", "require_approval", true),
          "message": newJNull() # TODO: Maybe let instance admins customize thru a config option
        },
        "contact": {
          "email": config.getStringOrDefault("instance","email",""),
          "account": admin_account
        },
        "rules": rules
      }
  
  req.respond(200, headers, $(result))

proc phAbout*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  var result = %* {
    "version": lib.phVersion,
    "mastoapi_version": lib.phMastoCompat,
    "source_url": lib.phSourceUrl,
    "kdf": crypto.kdf,
    "crash_dir": lib.globalCrashDir
  }
  req.respond(200, headers, $(result))

const apiRoutes* =  {
  # URLRoute : (HttpMethod, RouteProcedure)
  # /api/ is already inserted before every URLRoute
  "v1/instance": ("GET", v1InstanceView),
  "v2/instance": ("GET", v2InstanceView),
  "ph/v1/about": ("GET", phAbout)
}.toTable
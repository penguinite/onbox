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
# onbox/api/instance.nim:
## This module contains all the routes for the instance method in the api

# From somewhere in Onbox
import onbox/[entities, routes, conf]

# From somewhere in the standard library
import std/[json]

# From nimble/other sources
import mummy, waterpark/postgres

proc v1InstanceView*(req: Request) = 
  configPool.withConnection config:
    dbPool.withConnection db:
      req.respond(200, createHeaders("application/json"), $(v1Instance(db, config)))

proc v2InstanceView*(req: Request) = 
  configPool.withConnection config:
    dbPool.withConnection db:
      req.respond(200, createHeaders("application/json"), $(v2Instance(db, config)))

proc v1InstanceExtendedDescription*(req: Request) =
  configPool.withConnection config:
    req.respond(200, createHeaders("application/json"), $(extendedDescription(config)))

proc v1InstanceRules*(req: Request) =
  configPool.withConnection config:
    req.respond(200, createHeaders("application/json"), $(rules(config)))

# MISSING: [
# /api/v1/instance/translation_languages
# /api/v1/instance/domain_blocks
# /api/v1/instance/activity
# /api/v1/instance/peers
# ]
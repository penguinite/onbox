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
# api/ph.nim:
## This module contains all the routes for the ph method in the api


# From somewhere in Quark
import quark/[crypto]

# From somewhere in Pothole
import pothole/[lib]

# From somewhere in the standard library
import std/[json]

# From nimble/other sources
import mummy

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
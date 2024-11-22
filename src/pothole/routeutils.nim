# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
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

# From somewhere in Pothole
import pothole/private/[jsonhelpers, reqhelpers, resphelpers]
import pothole/[database, conf]

# From the standard library
import std/mimetypes
from std/strutils import parseInt, `%`

# From elsewhere
import waterpark/postgres

# Export everything
export jsonhelpers, reqhelpers, resphelpers, postgres

const mimedb*: MimeDB = newMimetypes()

var
  configPool*: ConfigPool
  dbPool*: PostgresPool

proc realURL*(config: ConfigTable): string =
  return "http://" & config.getString("instance", "uri") & config.getStringOrDefault("web", "endpoint", "/")

proc initEverythingForRoutes*() = 
  configPool = newConfigPool(parseInt(getEnvOrDefault("POTHOLE_CONFIG_SIZE", "75")))

  configPool.withConnection config:
    dbPool = newPostgresPool(
      config.getIntOrDefault("db", "pool_size", 10),
      config.getdbHost(),
      config.getdbUser(),
      config.getdbPass(),
      config.getdbName()
    )
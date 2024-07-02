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

# From somewhere in Quark
import quark/[user, post]

# From somewhere in Pothole
import conf, assets, database, routeutils

# From somewhere in the standard library
import std/[tables]
import std/strutils except isEmptyOrWhitespace, parseBool

# From nimble/other sources
import mummy, temple, waterpark/postgres

let configPool* = newConfigPool()

var
  dbPool: PostgresPool
  templatePool: TemplatingPool

configPool.withConnection config:
  dbPool = newPostgresPool(
    config.getIntOrDefault("db", "pool_size", 10),
    config.getdbHost(),
    config.getdbUser(),
    config.getdbPass(),
    config.getdbName()
  )

  dbPool.withConnection db:
    templatePool = newTemplatingPool(
      config.getIntOrDefault("misc", "templating_pool_size", 75),
      config,
      db
    )


const renderURLs*: Table[string,string] = {
  "/": "index.html", 
  "/about": "about.html", "/about/more": "about.html", # About pages, they run off of the same template.
}.toTable

proc serveAndRender*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  req.respond(200, headers, "Done")
  echo req.path

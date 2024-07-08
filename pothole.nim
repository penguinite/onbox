# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
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

# From somewhere in Quark
import quark/[database]

# From somewhere in Pothole
import pothole/[routes, lib, conf, database, assets, api, routeutils]

# From standard library
import std/[tables]
from std/strutils import join

# From nimble
import mummy, mummy/routers

echo "Pothole version ", lib.phVersion 
echo "Copyright © Leo Gavilieau 2022-2023." 
echo "Copyright © penguinite <penguinite@tuta.io> 2024." 
echo "Licensed under the GNU Affero General Public License version 3 or later" 

when not defined(useMalloc):
  {.warning: "Pothole is suspectible to a memory leak, which, for now, can only be fixed by supplying the -d:useMalloc".}
  {.warning: "Your build does not supply -d:useMalloc, therefore it is susceptible to a memory leak".}

proc exit() {.noconv.} =
  error "Interrupted by Ctrl+C"
# Catch Ctrl+C so we can exit our way.
setControlCHook(exit)

echo "Using ", getConfigFilename(), " as config file"

let config = setup(getConfigFilename())
var port = 3500
if config.exists("web","port"):
  port = config.getInt("web","port")

if not hasDbHost(config):
  log "Couldn't retrieve database host. Using \"127.0.0.1:5432\" as default"

if not hasDbName(config):
  log "Couldn't retrieve database name. Using \"pothole\" as default"

if not hasDbUser(config):
  log "Couldn't retrieve database user login. Using \"pothole\" as default"
  
if not hasDbPass(config):
  log "Couldn't find database user password from the config file or environment, did you configure pothole correctly?"
  error "Database user password couldn't be found."

log "Opening database at ", config.getDbHost()

# Initialize database
discard setup(
  config.getDbName(),
  config.getDbUser(),
  config.getDbHost(),
  config.getDbPass()
)

# Create directory for pure static files
discard initStatic(config)
discard initTemplates(config)


var router: Router
for url in renderURLs.keys:
  router.get(url, serveAndRender)
  # A hacky way to make sure that /about/ and /about both get
  # handled. 
  if url != "/":
    router.get(url & "/", serveAndRender)

router.get("/static/*", serveStatic)
# Common file extensions that we want to serve in the root
# This means we can add favicon.ico, robots.txt and so on.
for url in @[
  "/*.txt", "/*.svg", "/*.ico", "/*.png", "/*.webmanifest", "/*.jpg", "/*.webp", "/*.css", "/*.html"
]:
  router.get(url, serveStatic)

# Add API routes
for url, route in apiRoutes.pairs:
  router.addRoute(route[0], "/api/" & url, route[1])
  router.addRoute(route[0], "/api/" & url & "/", route[1]) # Trailing slash fix.

log "Serving on http://localhost:" & $port
initEverythingForRoutes()
newServer(router).serve(Port(port))
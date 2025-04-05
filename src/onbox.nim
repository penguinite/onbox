# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
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
import onbox/[shared, conf, routes, database, web]

# From standard library
import std/[strutils, os]

# From third-parties
import mummy, mummy/routers, iniplus, waterpark/postgres

log "Onbox version ", version
log "Copyright © Leo Gavilieau <xmoo@privacyrequired.com> 2022-2023"
log "Copyright © penguinite <penguinite@tuta.io> 2024-2025"
log "Licensed under the GNU Affero General Public License version 3 or later"

when not defined(useMalloc):
  {.warning: "Onbox is suspectible to a memory leak, which, for now, can only be fixed by supplying the -d:useMalloc compile-time option".}
  {.warning: "Your build does not supply -d:useMalloc, therefore it is susceptible to a memory leak".}
  log "This build of Onbox was built without -d:useMalloc, and is thus suspectible to a memory leak"

proc exit() {.noconv.} =
  error "Interrupted by Ctrl+C"
# Catch Ctrl+C so we can exit our way.
setControlCHook(exit)

log "Using ", getConfigFilename(), " as config file"

let config = parseFile(getConfigFilename())

var port = 3500
if config.exists("web","port"):
  port = config.getInt("web","port")

# Provide useful hints on when default values are used...
# Erroring out if a password for the database does not exist.

if not (config.exists("db","host") or existsEnv("ONBOX_DBHOST")):
  log "Couldn't retrieve database host. Using \"127.0.0.1:5432\" as default"

if not (config.exists("db","name") or existsEnv("ONBOX_DBNAME")):
  log "Couldn't retrieve database name. Using \"onbox\" as default"

if not (config.exists("db","user") or existsEnv("ONBOX_DBUSER")):
  log "Couldn't retrieve database user login. Using \"onbox\" as default"
  
if not (config.exists("db","password") or existsEnv("ONBOX_DBPASS")):
  log "Couldn't find database user password from the config file or environment, did you configure this program correctly?"
  error "Database user password couldn't be found."

# Warn the administrator if users are required to verify emails
# and the email hasn't been configured.
if config.getBoolOrDefault("user", "require_verification",false) and config.getBoolOrDefault("email","enabled",false):
  log "Users are required to verify their emails but no email server has been configured."
  log "Please set email to \"true\" or set require_verification to \"false\" to hide this warning."

log "Opening database at ", config.getDbHost()

var router: Router

# Add API & web routes
for route in mummyRoutes:
  router.addRoute(route[1], route[0], route[2])
  router.addRoute(route[1], route[0] & "/", route[2]) # Trailing slash fix.
router.get("/", serveHome)

log "Serving on http://localhost:" & $port

var size = 50
if existsEnv("ONBOX_CONFIG_SIZE"):
  size = parseInt(getEnv("ONBOX_CONFIG_SIZE"))

configPool = newConfigPool(size)
dbPool = newPostgresPool(
  config.getIntOrDefault("misc", "db_pool_size", 10),
  config.getdbHost(),
  config.getdbUser(),
  config.getdbPass(),
  config.getdbName()
)

newServer(router).serve(Port(port))
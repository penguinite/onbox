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

# From Pothole
import potholepkg/[lib, conf, database, routes]

# From standard library
import std/tables
from std/strutils import join

proc exit() {.noconv.} =
  echo "Interrupted by Ctrl+C"
  quit(1)

# From nimble
import mummy, mummy/routers

echo "Pothole version ", lib.version 
echo "Copyright © Leo Gavilieau 2022-2023." 
echo "Copyright © penguinite <penguinite@tuta.io> 2024." 
echo "Licensed under the GNU Affero General Public License version 3 or later" 

# Catch Ctrl+C so we can exit without causing a stacktrace
setControlCHook(exit)

echo "Using ", getConfigFilename(), " as config file"

let config = setup(getConfigFilename())
var port = 3500
if config.exists("web","port"):
  port = config.getInt("web","port")

# Initialize database
discard setup(config)

log "Running on http://localhost:" & $port

proc basicLog(lvl: LogLevel, args: varargs[string,`$`]) =
  case lvl:
  of DebugLevel: log "WebDebug: ", args.join
  of InfoLevel: log "WebInfo: ", args.join
  of ErrorLevel: log "WebError: ", args.join

var router: Router
for ur in staticURLs.keys: 
  router.get(ur, serveStatic)
router.get("/css/style.css", serveCSS)
#router.get("/showRandomPosts/", randomPosts)
router.get("/auth/sign_up", get_auth_signup)
router.post("/auth/sign_up", post_auth_signup)

var server = newServer(router, nil, basicLog)
server.serve(Port(port))
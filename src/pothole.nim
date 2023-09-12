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
import libpothole/[lib, conf, database]
import routes

# From standard library
import std/strutils except isEmptyOrWhitespace
import std/[os, tables]

proc exit() {.noconv.} =
  echo "Interrupted by Ctrl+C"
  quit(1)

# From nimble
import mummy, mummy/routers

echo "Pothole version ", lib.version 
echo "Copyright © Leo Gavilieau 2022-2023." 
echo "Licensed under the GNU Affero General Public License version 3 or later" 

# Catch Ctrl+C so we can exit without causing a stacktrace
setControlCHook(exit)

echo "Using " & getConfigFilename() & " as config file"

let config = setup(getConfigFilename())
var port = 3500
if config.exists("web","port"):
  port = config.getInt("web","port")

when dbEngine == "sqlite":
  discard init(config)

echo "Running on http://localhost:" & $port

var router: Router

for url in staticURLs.keys:
  router.get(url, serveStatic)
  if not url.endsWith('/'):
    router.get(url & "/", serveStatic)
router.get("/css/style.css", serveCSS)

let server = newServer(router)
server.serve(Port(port))
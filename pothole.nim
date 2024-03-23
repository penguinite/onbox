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

proc exit() {.noconv.} =
  echo "Interrupted by Ctrl+C"
  quit(1)

# From nimble
import prologue

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

echo "Running on http://localhost:" & $port

when defined(debug):
  const debugMode = true
else:
  const debugMode = false

let settings = newSettings(
  debug = debugMode,
  port = Port(port),
  appName = "Pothole"
)

var app = newApp(settings)
for ur in staticURLs.keys: 
  app.get(ur, serveStatic)
app.get("/css/style.css", serveCSS)
app.get("/showRandomPosts/", randomPosts)
app.get("/auth/sign_up", get_auth_signup)
app.post("/auth/sign_up", post_auth_signup)

app.run()
# Copyright © Pothole Project 2022-2023
# Licensed under the AGPL version 3 or later.

# From Pothole
import lib, conf, db, routes

# From standard library
from std/os import existsEnv, getEnv
from std/parsecfg import loadConfig
from std/strutils import split, parseInt, toLower

# From nimble
import prologue

echo("Pothole version ", lib.version)
echo("Copyright © Leo Gavilieau 2022-2023.")
echo("Licensed under the GNU Affero General Public License version 3 or later")

# Catch Ctrl+C so we can exit without causing a stacktrace
setControlCHook(lib.exit)

var configfile: string = "pothole.conf"
if existsEnv("POTHOLE_CONFIG"):
  configfile = getEnv("POTHOLE_CONFIG")

echo("Config file used: ", configfile)

if conf.setup(configfile) == false:
  error("Failed to load configuration file!", "main.startup")

# Now... We have to check if our required configuration
# options are actually there
for x in lib.requiredConfigOptions:
  var list = x.split(":")
  if exists(list[0],list[1]):
    continue
  else:
    error("Missing key " & list[1] & " in section " & list[0], "main.startup")

# Initialize the database
echo("Initializing database")
if not db.init(): # Wrap over specific database engine
  error "Database initialization failed", "main.startup"

var realport = 3500 # 3500 is the default port.
if exists("web","port"):
  realport = parseInt(get("web","port"))

var debugMode:bool;
when defined(debug):
  debugMode = true
else:
  echo("Listening on port " & $realport)
  debugMode = false


while isMainModule:
  # routes.nim contains all the actual procedures for routing.
  let settings = newSettings(
    appName = "Pothole",
    debug = debugMode,
    port = Port(realport)
  )
  var app = newApp(settings = settings)
  app.addRoute("/", index)
  app.run()





# And we all *shut* down...
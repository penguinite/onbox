# Copyright © Pothole Project 2022-2023
# Licensed under the AGPL version 3 or later.

when defined(windows):
  {.fatal: "Windows is not supported!".}

# From Pothole
import lib, conf, db, routes

# From standard library
from std/os import existsEnv, getEnv, dirExists, createDir
from std/parsecfg import loadConfig
from std/strutils import split, parseInt, toLower

# From nimble
import jester

echo("Pothole version ", lib.version)
echo("Copyright © Leo Gavilieau 2022-2023.")
echo("Licensed under the GNU Affero General Public License version 3 or later")

# Catch Ctrl+C so we can exit without causing a stacktrace
setControlCHook(lib.exit)

var configfile: string = "pothole.conf"
if existsEnv("POTHOLE_CONFIG"):
  configfile = getEnv("POTHOLE_CONFIG")

echo("Config file used: ", configfile)

if conf.setup(loadConfig(configfile)) == false:
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
discard init() # Wrap over specific database engine

# Fetch port from config file
var realport = Port(3500)
if exists("web","port"):
  realport = Port(parseInt(get("web","port")))

while isMainModule:
  let settings = newSettings(port=realport)
  var app = initJester(potholeRouter, settings=settings)
  # Start the web server. Let's hope for good luck!
  app.serve()


exit()
# And we all *shut* down...
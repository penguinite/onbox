# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.

# From Pothole
import lib

# From standard library
import std/os
import std/parsecfg

# From nimble
import jester

var configfile: string = "pothole.conf"
if existsEnv("POTHOLE_CONFIG"):
  configfile = getEnv("POTHOLE_CONFIG")

# We have to initialize it for every specific thread.
# Fortunately conf.setup() is independent, unfortunately
# It's quite slow.
#
# Maybe someone can send a GitHub issue to the Jester devs
# so they can fix this and allows us to use let instead of const?
{.gcsafe.}:
  try:
    var dict = loadConfig(configfile)
  except:
    error("Failed to load configuration file!","main.startup")

echo("Pothole version ")
echo("Copyright © Pothole Project 2022.")
echo("Licensed under the GNU Affero General Public License version 3 or later")

router main:
  get "/":
    resp Http200, ""
  
while isMainModule:
    var realjester = initJester(main, settings=newSettings(port=Port(3500)))
    realjester.serve()


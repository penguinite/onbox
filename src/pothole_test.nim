import conf, os, lib, db, assets, potcode

var configfile: string = "pothole.conf"
if existsEnv("POTHOLE_CONFIG"):
  configfile = getEnv("POTHOLE_CONFIG")

echo("Config file used: ", configfile)

if conf.setup(configfile) == false:
  error("Failed to load configuration file!", "main.startup")

discard db.init()

echo(parseInternal(fetchStatic("index.html")))
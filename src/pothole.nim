# Copyright © Pothole Project 2022-2023
# Licensed under the AGPL version 3 or later.

# From Pothole
import lib
import conf
import routes
import db
import data 
import crypto

# From standard library
import std/[strutils, parsecfg, os]

# From nimble
import jester

echo("Pothole version ", lib.version)
echo("Copyright © Louie Quartz 2022-2023.")
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

# Let's create static folders!
# Or at the very least, check they exist!
if exists("folders","static"):
  staticFolder = conf.get("folders","static")

if exists("folders","uploads"):
  uploadsFolder = conf.get("folders","uploads")

if exists("folders","blogs"):
  blogsFolder = conf.get("folders","blogs")

if staticFolder[len(staticFolder) - 1] == '/':
  discard # Nim does not have "does not equal" operator
else:
  staticFolder.add("/")

if uploadsFolder[len(uploadsFolder) - 1] == '/':
  discard # Nim does not have "does not equal" operator
else:
  uploadsFolder.add("/")

if blogsFolder[len(blogsFolder) - 1] == '/':
  discard # Nim does not have "does not equal" operator
else:
  blogsFolder.add("/")

proc c(folder:string): bool =
  if not dirExists(folder):
    try:
      createDir(folder)
    except:
      return false
  return true

if c(staticFolder) == false or c(uploadsFolder) == false or c(blogsFolder) == false:
  var caller = "main.startup.FolderCheck"
  debug("Static folder: " & staticFolder, caller)
  debug("Uploads folder: " & uploadsFolder, caller)
  debug("Blogs folder: " & blogsFolder, caller)
  error("A special folder that is vital for Pothole doesn't exist or failed to be created.",caller)

# Initialize the database
echo("Initializing database")
db.init()

# Fetch port from config file
var realport = Port(3500)
if exists("web","port"):
  realport = Port(parseInt(get("web","port")))

# Some users for debugging
var mex = 0
inc(mex) # 1
echo(mex)
var user: User;
#var user = newUser("quartz","123",true)
user.id = randomString()
user.password = hash("123",randomString(18))
user.handle = "quartz"
user.local = true
user.name = "Louie Quartz"
user.email = "quartz@quartz.quartz"
user.bio = "Hi! I create stuff\nStay safe!"
user.is_frozen = false
inc(mex) # 2
echo(mex)
discard db.addUser(user)
inc(mex) # 3
echo(mex)
echo("Trying to retrieve user")
inc(mex) # 4
echo(mex)
echo(getIdFromHandle(user.handle))
inc(mex) # 5
echo(mex)


while isMainModule:
  let settings = newSettings(port=realport)
  var app = initJester(potholeRouter, settings=settings)
  # Start the web server. Let's hope for good luck!
  app.serve()

  exit()





# And we all *shut* down...
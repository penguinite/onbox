# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.

import conf # For fetching configuration data
import env # For fetching information from the environment
import lib # Shared data, procedures etc. 
import db # For database operations
import os # For file system operations

import std/oids

echo("Pothole version ", lib.ver)
echo("Copyright © Pothole Project 2022.")
echo("Licensed under the GNU Affero General Public License version 3 or later")
echo("Using config file: ", env.fetchConfig())

if existsEnv("POTHOLE_DEBUG"):
    lib.debugMode = 1;

lib.debug("Using config file: " & $env.fetchConfig(),"main.startup")
lib.debug("Current working directory: " & $os.getCurrentDir(),"main.startup")

# Setup conf.nim to parse the configuration file
conf.setup(env.fetchConfig())

# Setup db.nim
db.setup(conf.getString("dbtype"))

var customMan: User;
customMan.id = $genOid()
customMan.name = "quartz"
customMan.email = "trustymusty@protonmail.com"
customMan.handle = "Louie Quartz"
customMan.password = "123"
customMan.bio = "I create stuff! Stay safe.\nPronouns: any"
db.addUser(customMan)


lib.exit()

# And we all *shut* down...
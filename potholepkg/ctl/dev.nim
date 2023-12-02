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
#
# ctl/dev.nim:
## Developer operations for Potholectl
## Anything a contributor to Pothole would need can be found here.

# From ctl/ folder in Pothole
import shared

# From elsewhere in Pothole
import ../[lib, conf]
import ../db/common

# From standard libraries
import std/[os, osproc, tables, strutils]

const envVars = {
  "PHDB_HOST": "127.0.0.1:5432",
  "PHDB_NAME": "pothole",
  "PHDB_USER": "pothole",
  "PHDB_PASS": "SOMETHING_SECRET"
}.toTable

proc initEnv(config: ConfigTable) =
  for env, val in envVars.pairs:
    # Woah! A powerful oneliner!
    let key = env.split('_')[1][0..3].toLower()
    try:
      putEnv(env, config.getStringOrDefault("db",key,val))
    except CatchableError as err:
      log "Couldn't set environment variable \"", env, "\" to its value: ", err.msg

proc cleanEnv() =
  for env in envVars.keys:
    try:
      delEnv(env)
    except CatchableError as err:
      log "Couldn't delete environment variables \"", env, "\": ", err.msg

proc initDb(config: ConfigTable) =
  proc exec(cmd: string): string =
    try:
      log "Executing: ", cmd
      let (output,exitCode) = execCmdEx(cmd)
      if exitCode != 0:
        log "Command returns ", exitCode
        return ""
      return output
    except CatchableError as err:
      log "Couldn't run command:", err.msg

  discard exec "docker pull postgres"

  let id = exec "docker run --name potholeDb -p 5455:5432 -e POSTGRES_USER=$1 -e POSTGRES_PASSWORD=$2 -e POSTGRES_DB=$3 -d postgres" % [getDbUser(config), getDbPass(config), getDbName(config)]

  if id == "":
    error "Please investigate the above errors before trying again."
  else:
    log "Saving id to .db_pid"
    var file = open(".db_pid", fmWrite)
    file.write(id)
    file.close()

proc cleanDb(config: ConfigTable) =
  return

proc purgeDb() =
  proc exec(cmd: string) =
    try:
      log "Executing: ", cmd
      discard execCmd(cmd)
    except CatchableError as err:
      log "Couldn't run command:", err.msg
  
  if not fileExists(".db_pid"):
    error "Couldn't find file \".db_pid\", did you setup the server?"

  let id = readFile(".db_pid")

  exec "docker kill " & id
  exec "docker rm " & id
  exec "docker rmi postgres"


proc envvarsDontExist(): bool =
  for env in envVars.keys:
    if not existsEnv(env): return true
  return false

proc processCmd*(cmd: string, data: seq[string], args: Table[string,string]) =
  if args.check("h","help"):
    helpPrompt("dev",cmd)

  var config: ConfigTable
  if args.check("c", "config"):
    config = conf.setup(args.get("c","config"))
  else:
    config = conf.setup(getConfigFilename())

  case cmd:
  of "setup":
    initEnv(config)
    if config.isNil() and envvarsDontExist():
      log "No way to get the login details required to clean the database."
      log "Either you have no readable config file or no environment variables"
      log "You might be able to recover from this error by running the setup_env command first"
      return
    initDb(config)
  of "setup_db":
    if config.isNil() and envvarsDontExist():
      log "No way to get the login details required to clean the database."
      log "Either you have no readable config file or no environment variables"
      log "You might be able to recover from this error by running the setup_env command first"
      return
    initDb(config)
  of "setup_env":
    initEnv(config)
  of "clean":
    if config.isNil() and envvarsDontExist():
      log "No way to get the login details required to clean the database."
      log "Either you have no readable config file or no environment variables"
      log "You might be able to recover from this error by running the setup_env command first"
      return
    cleanDb(config)
  of "purge_env":
    cleanEnv()
  of "purge":
    cleanDb(config)
    cleanEnv()
    purgeDb()
    for dir in @["static/","uploads/","build/","docs/public/"]:
      if dirExists(dir): removeDir(dir)
  else:
    log "Unknown command: \"", cmd, "\""
    helpPrompt("dev")

    
#  genCmd("setup", "Initializes everything for local development"),
#  genCmd("setup_db", "Creates a postgres container for local development"),
#  genCmd("setup_env", "Initializes environment variables."),
#  genCmd("clean", "Removes all tables inside of a postgres database container"),
#  genCmd("purge_env", "Cleans up environment variables"),
#  genCmd("purge", "Cleans up everything, including images, envvars and build folders")
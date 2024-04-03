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
import ../[lib, conf, database]

# From standard libraries
import std/[os, osproc, tables, strutils]

const envVars = {
  "PHDB_HOST": "127.0.0.1:5432",
  "PHDB_NAME": "pothole",
  "PHDB_USER": "pothole",
  "PHDB_PASS": "SOMETHING_SECRET"
}.toTable

proc initEnv(config: ConfigTable,outputfile: string = "pothole_envs") =
  var data = ""
  for env, val in envVars.pairs:
    # Woah! A powerful oneliner!
    let key = env.split('_')[1][0..3].toLower()
    data.add "export " & env & "=\"" & config.getStringOrDefault("db",key,val)  & "\"\n"
  
  # Write to file
  log "Writing script to ", outputfile
  var file = open(outputfile, fmWrite)
  file.write(data)
  file.close()

proc cleanEnv(outputfile: string = "pothole_envs") =
  var data = ""
  for env in envVars.keys:
    try:
      data.add("unset " & env & "\n")
    except CatchableError as err:
      log "Couldn't delete environment variables \"", env, "\": ", err.msg
  
  # Write to file
  log "Writing script to ", outputfile
  var file = open(outputfile, fmWrite)
  file.write(data)
  file.close()

proc initDb(config: ConfigTable) =
  proc exec(cmd: string): string =
    try:
      log "Executing: ", cmd
      let (output,exitCode) = execCmdEx(cmd)
      if exitCode != 0:
        log "Command returns code: ", exitCode
        log "command returns output: ", output
        return ""
      return output
    except CatchableError as err:
      log "Couldn't run command:", err.msg

  discard exec "docker pull postgres:alpine"

  let id = exec "docker run --name potholeDb -d -p 5432:5432 -e POSTGRES_USER=$1 -e POSTGRES_PASSWORD=$2 -e POSTGRES_DB=$3 postgres:alpine" % [getDbUser(config), getDbPass(config), getDbName(config)]

  if id == "":
    error "Please investigate the above errors before trying again."

proc purgeDb() =
  proc exec(cmd: string) =
    try:
      log "Executing: ", cmd
      discard execCmd(cmd)
    except CatchableError as err:
      log "Couldn't run command:", err.msg
  
  exec "docker kill potholeDb"
  exec "docker rm potholeDb"

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
  of "db":
    if config.isNil() and envvarsDontExist():
      log "No way to get the login details required to clean the database."
      log "Either you have no readable config file or no environment variables"
      log "You might be able to recover from this error by running the setup_env command first"
      return
    if args.check("d","delete"):
      purgeDb()
    else:
      initDb(config)
  of "env":
    let outputFile = args.getOrDefault("o","output","pothole_envs")
    if args.check("d","delete"):
      cleanEnv(outputFile)
    else:
      config.initEnv(outputFile)
  of "clean":
    if config.isNil() and envvarsDontExist():
      log "No way to get the login details required to clean the database."
      log "Either you have no readable config file or no environment variables"
      log "You might be able to recover from this error by running the setup_env command first"
      return
    cleanDb(config)
  of "delete":
    purgeDb()
  of "psql":
    if config.isNil() and envvarsDontExist():
      log "No way to get the login details required to access the database."
      log "Either you have no readable config file or no environment variables"
      log "You might be able to recover from this error by running the setup_env command first"
      return

    log "Executing: docker exec -it potholeDb psql -U ", config.getDbUser(), " ", config.getDbName()
    discard execShellCmd "docker exec -it potholeDb psql -U " & config.getDbUser() & " " & config.getDbName()

  of "purge":
    cleanEnv()
    purgeDb()
  
    log "Executing: docker rmi postgres"
    discard execCmd "docker rmi postgres"

    for dir in @["static/","uploads/","build/","docs/public/"]:
      if dirExists(dir): removeDir(dir)
  else:
    helpPrompt("dev")
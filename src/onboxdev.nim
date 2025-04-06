# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
#
# This file is part of Onbox.
# 
# Onbox is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Onbox is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Onbox. If not, see <https://www.gnu.org/licenses/>. 
#
# onboxdev:
## A developer-focused convenience tool.
# From Onbox:
import onbox/[database, shared, conf]

# Standard library
import std/[strutils, osproc, rdstdin]

# Third-party libraries
import cligen, iniplus, db_connector/db_postgres

## Utility stuff first!
proc getConfig(c = "onbox.conf"): ConfigTable =
  return iniplus.parseFile(getConfigFilename(c))

proc getDb(c: ConfigTable): DbConn =
  return db_postgres.open(
      c.getDbHost(),
      c.getDbUser(),
      c.getDbPass(),
      c.getDbName(),
    )

proc exec(cmd: string): string {.discardable.} =
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

## Then the commands themselves!!

proc shell(name = "onboxDb", config = "onbox.conf"): int =
  ## Assuming a db_docker environment,
  ## launch a psql shell in the database.
  let cnf = getConfig(config)
  execCmd "docker exec -it $1 psql -U $2 $3" % [
    name,
    cnf.getDbUser(),
    cnf.getDbName()
  ]

proc test_user(name = "onboxDb", config = "onbox.conf"): int =
  ## Assuming a db_docker environment,
  ## launch a psql shell in the database.
  let
    cnf = getConfig(config)
    db = getDb(config)

  var user = newUser(
    handle = "test",
    local = true,
    password = "pass"
  )

  user.email = ""
  user.name = display
  user.bio = bio
  user.roles = @[0,1,2,3]
    
  db.addUser(user)
  
  echo "Created a test user!"
  echo "Username: test"
  echo "Password: pass"
  echo "Beware: The user has full admin and mod control over the instance."

dispatchMulti(
  [shell, help = {"name": "Name of database container", "config" = "Location to config file"}],
  [test_user, help = {"config" = "Location to config file"}]
)

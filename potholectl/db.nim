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
# ctl/db.nim:
## Database operations for Potholectl
## This simply parses the subsystem & command (and maybe arguments)
## and it calls the appropriate function from src/db.nim

# From somewhere in Potholectl
import shared

# From somewhere in Quark
import quark/[crypto, database, strextra]

# From somewhere in Pothole
import pothole/[database, lib, conf]

# From standard libraries
from std/tables import Table
from std/strutils import split, `%`

# From elsewhere
import rng

proc processCmd*(cmd: string, data: seq[string], args: Table[string,string]) =
  if args.check("h","help"):
    helpPrompt("db",cmd)

  var config: ConfigTable
  if args.check("c", "config"):
    config = conf.setup(args.get("c","config"))
  else:
    config = conf.setup(getConfigFilename())

  case cmd:
  of "schema_check", "init":
    log "Re-running database initialization with schema checking enabled."
    discard setup(
      config.getDbName(),
      config.getDbUser(),
      config.getDbHost(),
      config.getDbPass(),
      true
    )
  of "clean": 
    log "Cleaning everything in database"
    init(
      config.getDbName(),
      config.getDbUser(),
      config.getDbHost(),
      config.getDbPass(),
    ).cleanDb()
  of "docker":
    log "Setting up postgres docker container according to config file"
    var
      # Sick one liner to figure out the port we need to expose.
      port = split(getDbHost(config), ":")[high(split(getDbHost(config), ":"))]
      password = config.getDbPass()
      containerName = "potholeDb"
      name = config.getDbName()
      user = config.getDbUser()
      host = ""
    
    if args.check("n","name"):
      containerName = args.get("n","name")

    if port.isEmptyOrWhitespace():
      port = "5432"

    if not args.check("e","expose-externally"):
      if args.check("6","ipv6"):
        host.add("::1:")
      else:
        host.add("127.0.0.1:")
    host.add(port & ":5432")
    
    if password == "SOMETHING_SECRET" and not args.check("a","allow-weak-password"):
      log "Changing vulnerable database password to something more secure"
      password = randstr(64)
      echo "Please update the config file to reflect the following changes:"
      echo "[db] password is now \"", password, "\""
  
    log "Pulling docker container"
    discard exec "docker pull postgres:alpine"
    log "Creating the container itself"
    let id = exec "docker run --name $# -d -p $# -e POSTGRES_USER=$# -e POSTGRES_PASSWORD=$# -e POSTGRES_DB=$# postgres:alpine" % [containerName, host, user, password, name]
    if id == "":
      error "Please investigate the above errors before trying again."

  else:
    helpPrompt("db")
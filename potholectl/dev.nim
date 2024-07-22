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
# potholectl/dev.nim:
## Developer operations for Potholectl
## Anything a contributor to Pothole would need can be found here.

# From somewhere in Potholectl
import potholectl/shared

# From somewhere in Pothole
import pothole/[lib, conf, database]

# From standard libraries
import std/[os, strutils]

proc db*(config = "pothole.conf"): int =
  ## This command creates a postgres database container for development purposes.
  ## 
  ## It uses the values provided by configuration file, so if you're still using default values then you're using an insecure password.
  let cnf = conf.setup(config)
  discard exec "docker pull postgres:alpine"
  let id = exec "docker run --name potholeDb -d -p 5432:5432 -e POSTGRES_USER=$1 -e POSTGRES_PASSWORD=$2 -e POSTGRES_DB=$3 postgres:alpine" % [getDbUser(cnf), getDbPass(cnf), getDbName(cnf)]
  if id == "":
    error "Please investigate the above errors before trying again."
  return 0

proc clean*(config = "pothole.conf"): int =
  ## This command clears every table inside the postgres container, useful for when you need a blank slate inbetween tests.
  let cnf = conf.setup(config)
  echo "Clearing database."
  init(
    cnf.getDbName(),
    cnf.getDbUser(),
    cnf.getDbHost(),
    cnf.getDbPass(),
  ).cleanDb()

proc psql*(config = "pothole.conf"): int = 
  ## This command opens a psql shell in the database container.
  ## This is useful for debugging operations and generally figuring out where we went wrong. (in life)
  let
    cnf = conf.setup(config)
    cmd = "docker exec -it potholeDb psql -U " & cnf.getDbUser() & " " & cnf.getDbName()
  echo "Executing: ", cmd
  discard execShellCmd cmd

import cligen
dispatchMultiGen(
  ["dev"],
  [db, help= {"config": "Location to config file"}, mergeNames = @["potholectl", "dev"]],
  [clean, help= {"config": "Location to config file"}, mergeNames = @["potholectl", "dev"]],
  [psql, help= {"config": "Location to config file"}, mergeNames = @["potholectl", "dev"]]
)

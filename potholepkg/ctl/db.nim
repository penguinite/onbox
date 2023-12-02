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

# From ctl/ folder in Pothole
import shared

# From elsewhere in Pothole
import ../[database,lib,conf]

# From standard libraries
from std/tables import Table

proc processCmd*(cmd: string, data: seq[string], args: Table[string,string]) =
  if args.check("h","help"):
    helpPrompt("db",cmd)

  var config: ConfigTable
  if args.check("c", "config"):
    config = conf.setup(args.get("c","config"))
  else:
    config = conf.setup(getConfigFilename())

  case cmd:
  of "schema_check":
    log "Re-running database initialization with schema checking enabled."
    discard init(config,true)
  of "setup":
    # TODO: Spit out a config file and postgres script.
    return
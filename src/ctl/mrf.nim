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
# ctl/ext.nim:
## Operations related to extensions.
## It does stuff like reveal the embedded metadata and uh... stuff...

# From ctl/ folder in Pothole
import shared

# From elsewhere in Pothole
import ../libpothole/[lib,conf]

# From standard libraries
from std/tables import Table

proc processCmd*(cmd: string, data: seq[string], args: Table[string,string]) =
  if args.check("h","help"):
    helpPrompt("ext",cmd)

  var config: Table[string,string]
  if args.check("c", "config"):
    config = conf.setup(args.get("c","config"))
  else:
    config = conf.setup(getConfigFilename())

  case cmd:
  of "view":
    echo args
  of "check_config":
    echo args
  of "enable":
    echo args
  else:
    return
    
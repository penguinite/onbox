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
# ctl/template.nim:
## Operations related to templating.

# From somewhere in Potholectl
import shared

# From somewhere in Pothole
import pothole/[conf, database, lib]
from pothole/routeutils import prepareTable

# From somewhere in the standard library
import std/json

# From third-party programs
import temple

proc processCmd*(data: seq[string], args: Table[string,string]) =
  if args.check("h","help"):
    helpPrompt("template")
  
  # Initialize config
  var config: ConfigTable
  if args.check("c", "config"):
    config = conf.setup(args.get("c","config"))
  else:
    config = conf.setup(getConfigFilename())

  # Initialize database
  var db = setup(
    config.getDbName(),
    config.getDbUser(),
    config.getDbHost(),
    config.getDbPass()
  )

  # Initialize table
  var table = initTable[string, string]()
  if len(data) > 1:
    var jason: JsonNode
    try:
      jason = parseJSON(readFile(data[1]))
    except CatchableError as err:
      error "Couldn't open file \"", args.get("f","file"), "\": ", err.msg
    
    for key, val in jason.pairs:
      if val.kind == JString:
        table[key] = val.getStr()

  else:
    table = prepareTable(db, config)

  # Check if templating data is in a file
  # of it has been provided in the actual command
  var input = ""
  if len(data) > 0:
    try:
      input = readFile(data[0])
    except CatchableError as err:
      error "Couldn't open file \"", args.get("f","file"), "\": ", err.msg
  else:
    helpPrompt("template")
    error "No template data given."
  echo templateify(input, table)
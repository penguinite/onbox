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
# ctl/help.nim:
## Contains help dialogs for all subsystems and commands
## In potholectl.

from ../libpothole/lib import version
import std/[tables, strutils]

# This table contains help info for every file.
# It follows the format of SUBSYSTEM:COMMAND
# So fx. if you wanted to see what the
# "potholectl db init" command does then you'd use
# echo($helpTable["db:init"])
# If you wanted to see all the commands of the db subsystem
# then you would use "db" as it is
var helpTable*: Table[string, seq[string]] = initTable[string, seq[string]]()

const prefix* = """
Potholectl $#
Copyright (c) Leo Gavilieau 2023
Licensed under the GNU Affero GPL License under version 3 or later.
""" % [lib.version]

func genArg(short,long,desc: string): string =
  return "-" & short & ",--" & long & "\t\t;; " & desc

func genCmd(cmd,desc: string): string =
  return cmd & "\t\t-- " & desc

const helpDialog* = @[
  prefix,
  "Available subsystems: ",
  "",
  "Universal arguments: ",
  genArg("h","help","Displays help prompt for any given command and exits."),
  genArg("v","version","Display a version prompt and exits"),
]

helpTable["db"] = @[
  prefix,
  "Available commands:",
  genCmd("schema_check","Checks the database schema against the hardcoded values")
]

helpTable["db:schema_check"] = @[
  prefix,
  """
  This command initializes a database with schema checking enabled.
  You can use it to test if the database needs migration.
  """,
  "Available arguments:",
  genArg("c","config","Specify a config file to use")
]
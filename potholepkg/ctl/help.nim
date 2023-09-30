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

from ../lib import version
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
  return "-$#,--$#\t\t;; $#" % [short, long, desc]

func genCmd(cmd,desc: string): string =
  return "$#\t\t-- $#" % [cmd, desc]

const helpDialog* = @[
  prefix,
  "Available subsystems: ",
  genCmd("db","Database-related operations"),
  genCmd("mrf","MRF-related operations"),
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

helpTable["mrf"] = @[
  prefix,
  """
This subsystem handles "Extensions"/"Plugins" related operations.
Certain features in Pothole are extensible at run-time and this subsystem 
is there specifically to aid with debugging, enabling and making use of this
extensibility.

If its unclear what these commands do then, you should read the docs.
As some of them change the config file, which might or might not break stuff.

Available commands:
  """,
  genCmd("view", "Views information about a specific module."),
  genCmd("config_config", "Checks the config file for any errors related to extensions.")
]

helpTable["mrf:view"] = @[
  prefix,
  """
This command reads a custom MRF policy and shows its metadata.
You should supply the path to the module for this command, it does not
read the config file.

Available arguments:
  """,
  genArg("t","technical","Show non-human-friendly metadata. Ie. Technical data.")
]

helpTable["mrf:config_check"] = @[
  prefix,
  """
This command reads the config file and checks if the "MRF" section is valid.
It does not make any changes, it merely points out errors and potential fixes.

Available arguments:
  """,
  genArg("c","config","Path to configuration file.")
]

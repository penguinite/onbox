# Copyright © Leo Gavilieau 2023
# Licensed under the AGPL version 3 or later.
# 
# ctl/help.nim:
## Contains help dialogs for all subsystems and commands
## In potholectl.

from ../lib import version
import std/tables

# This table contains help info for every file.
# It follows the format of SUBSYSTEM:COMMAND
# So fx. if you wanted to see what the
# "potholectl db init" command does then you'd use
# echo($helpTable["db:init"])
# If you wanted to see all the commands of the db subsystem
# then you would use "db" as it is
var helpTable*: Table[string, seq[string]] = initTable[string, seq[string]]()

const prefix* = "Potholectl " & lib.version & "\nCopyright (c) Leo Gavilieau 2023\nLicensed under the GNU Affero GPL License under version 3 or later."

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
  genCmd("init","Initializes a database using the config file")
]

helpTable["db:init"] = @[
  prefix,
  "\nThis command initializes a database using values from the\nconfig file, this is not needed since potholectl automatically initializes\nthe database with no schema checking.",
  "\nAvailable arguments:",
  genArg("c","config","Specify a config file to use")
]
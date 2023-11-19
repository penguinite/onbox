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
# ctl/shared.nim:
## Shared procedures for potholectl.

# From ctl/ folder
import help

# From elsewhere in Pothole
import ../[lib, database]

# From standard library
import std/[tables]

var subsystems*: seq[string] = @[]
var commands*: seq[string] = @[]

proc initStuff*() =
  for key in helpTable.keys:
    if ':' in key:
      commands.add(key)
    else:
      subsystems.add(key)

proc helpPrompt*(subsystem:string = "", command: string = "") =
  ## A procedure to print the appropriate help dialog depending on subsystem and command.
  
  # Print the program-wide help dialog.
  if subsystem.isEmptyOrWhitespace():
    for str in helpDialog:
      echo(str)
    quit()
  
  # Print the subsystem help dialog
  if command.isEmptyOrWhitespace():
    for str in helpTable[subsystem]:
      echo(str)
    quit()
  
  # Print the command help dialog
  for x in helpTable[subsystem & ":" & command]:
    echo(x)
  quit()

  

proc check*(args: Table[string, string], short, long: string): bool =
  ## Checks if an argument has been given.
  for key in args.keys:
    if short == key or long == key: return true
  return false

proc get*(args: Table[string, string], short, long: string): string =
  ## Gets a command-line argument value. If there is no value to be retrieved then an empty string is returned.
  for key,val in args.pairs:
    if short == key or long == key: return val
  return ""


proc isSubsystem*(sys: string): bool =
  return sys in subsystems

proc isCommand*(sys, cmd: string): bool =
  return $(sys & ":" & cmd) in commands

proc versionPrompt*() =
  echo help.prefix
  quit()

proc initDb*(config: Table[string, string], schemaCheck: bool = false): DbConn = 
  ## Returns an initialized database connection.
  return init(config, false)
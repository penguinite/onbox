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
# potholectl:
## Potholectl is a command-line tool that aids in diagnosing problems
## or setting up instances. It provides a low-level tool to access
## Pothole's internals with.

# From Pothole
import potholepkg/lib

# From Pothole (ctl folder)
import potholepkg/ctl/[shared, db, mrf, dev, user]

# From standard library
import std/[os, parseopt, strutils, tables]

# Leave if no parameters were provided
if paramCount() < 1:
  helpPrompt()

#! Functions and procedures are declared here or somewhere in the ctl/ folder

var p = initOptParser()

var
  subsystem = "" # Subsystem is just fancy word for section.
  command = "" # This is the actual command to execute.
  data: seq[string] = @[] # Mandatory args are stored here
  args: Table[string, string] = initTable[string,string]()

# Potholectl follows this format: potholectl SUBSYSTEM [-OPTIONAL_ARGS] COMMAND MANDATORY_ARGS 
# ie. ./pothole db init --backend=native main.db
# or ./pothole conf parse pothole.conf
initStuff()
for kind, key, val in p.getopt():
  case kind

  of cmdArgument:
    if isSubsystem(key) and len(subsystem) < 1:
      subsystem = toLowerAscii(key)
      continue
    
    if isCommand(subsystem, key) and len(subsystem) > 0:
      command = toLowerAscii(key)
      continue

    data.add(key)

  of cmdLongOption, cmdShortOption:
    if len(val) > 0:
      args[key] = val
    else:
      args[key] = ""
      
  of cmdEnd: break

if args.check("v","version"):
  echo "Potholectl v" & lib.version
  quit(0)

case subsystem
of "db": db.processCmd(command, data, args)
of "mrf": mrf.processCmd(command, data, args)
of "dev": dev.processCmd(command, data, args)
of "user": user.processCmd(command, data, args)
else:
  # Just check the args as-is
  if args.check("h","help"):
    helpPrompt()
# Copyright © Leo Gavilieau 2023
# Licensed under the AGPL version 3 or later.
#
# potholectl:
## Potholectl is a command-line tool that aids in diagnosing problems
## or setting up instances. It provides a low-level tool to access
## Pothole's internals with.

# From Pothole
import lib

# From Pothole (ctl folder)
import ctl/[shared, db]

# From standard library
import std/[os, parseopt, strutils, tables]

# Leave if no parameters were provided
if paramCount() < 1:
  echo "Type -h or --help for help"
  lib.exit()

#! Functions and procedures are declared here or somewhere in the ctl/ folder

var p = initOptParser()

var subsystem = "" # Subsystem is just fancy word for section.
var command = "" # This is the actual command to execute.
var data: seq[string] = @[] # Mandatory args are stored here
var args: Table[string, string] = initTable[string,string]()

# Potholectl follows this format: potholectl SUBSYSTEM [-OPTIONAL_ARGS] COMMAND MANDATORY_ARGS 
# ie. ./pothole db init --backend=native main.db
# or ./pothole conf parse pothole.conf
for kind, key, val in p.getopt():
  case kind
  of cmdArgument:
    if isSubsystem(key) and len(subsystem) < 1:
      subsystem = toLowerAscii(key)
    if isCommand(subsystem, key) and len(subsystem) > 0:
      command = toLowerAscii(key)
    if len(subsystem) > 0 and len(command) > 0:
      data.add(key)
  of cmdLongOption, cmdShortOption:
    if len(val) > 0:
      args[key] = val
    else:
      args[key] = ""
  of cmdEnd: break

# Initialize the database and config parser
initDb()
initConf()

case subsystem
of "db":
  db.processCmd(command, data, args)
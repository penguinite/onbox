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
import ctl/[dialog, db]

# From standard library
import std/[os, parseopt]

# Leave if no parameters were provided
if paramCount() < 1:
  echo "Type -h or --help for help"
  lib.exit()

const helpDialog = @[
  "Potholectl " & lib.version,
  "Copyright (c) Leo Gavilieau 2023",
  "Licensed under the GNU Affero GPL License under version 3 or later.",
  "Available commands: ",
  "",
  "Universal arguments arguments: ",
  "-h,--help\t\t;; Displays help prompt for a command and exits",
  "-v,--version\t\t;; Displays a version prompt and exits"
]

#! Functions and procedures are declared here or somewhere in the ctl/ folder

var p = initOptParser()

var subsystem = "" # Subsystem is just fancy word for section.
var command = "" # This is the actual command to execute.
var args: seq[string] = @[] # Args are stored here.

# Potholectl follows this format: potholectl SUBSYSTEM [-OPTIONAL_ARGS] COMMAND MANDATORY_ARGS 
# ie. ./pothole db init --backend=native main.db
# or ./pothole conf parse pothole.conf
for kind, key, val in p.getopt():
  case kind
  of cmdArgument,cmdLongOption, cmdShortOption:
    if len(subsystem) < 0:
      subsystem = key
      continue
    if len(command) < 0:
      command = key
      continue
    args.add(key)
  of cmdEnd: break

case subsystem
of "db":
  db.processCmd(subsystem, key, args)
else:
  error("Unrecognizable arguments (Subsystem: " & subsystem & ", Cmd: " & command & "\nArgs: " & $args, "potholectl.startup")
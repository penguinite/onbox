# Copyright © Leo Gavilieau 2023
# Licensed under the AGPL version 3 or later.
#
# ctl/shared.nim:
## Shared procedures for potholectl.

# From ctl/ folder in Pothole
import help

# From elsewhere in Pothole
import ../lib, ../db, ../conf

# From standard library
import std/[tables,os]

const subsystems* = @["db"]
const commands* = @["db:init"]

proc helpPrompt*(subsystem, command: string = "") =
  ## A program that writes the entirety of the help prompt.
  if len(subsystem) > 0:
    if len(command) > 0:
      for x in helpTable[subsystem & ":" & command]:
        echo(x)
    else:
      for x in helpTable[subsystem]:
        echo(x)
  else:
    for x in helpDialog:
      echo(x)
  lib.exit()

proc checkArgs*(args: Table[string, string], short, long: string): bool =
  for key in args.keys:
    if short == key:
      return true
    if long == key:
      return true
  return false

proc getArg*(args: Table[string, string], short, long: string): string =
  for key,val in args.pairs:
    if short == key:
      return val
    if long == key:
      return val
  return ""


proc isSubsystem*(sys: string): bool =
  if sys in subsystems:
    return true
  return false

proc isCommand*(sys, cmd: string): bool =
  if $(sys & ":" & cmd) in commands:
    return true
  return false

proc versionPrompt*() =
  echo help.prefix
  lib.exit()

proc initDb*() = 
  echo("Initializing database")
  if not db.init(noSchemaCheck=true):
    error "Database initialization failed", "ctl/shared.initDb"

proc initConf*() =
  var configfile: string = "pothole.conf"
  if existsEnv("POTHOLE_CONFIG"):
    configfile = getEnv("POTHOLE_CONFIG")

  echo("Config file used: ", configfile)

  if conf.setup(configfile) == false:
    error("Failed to load configuration file!", "ctl/shared.initConf")
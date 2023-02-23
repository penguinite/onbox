# Copyright © Leo Gavilieau 2023
# Licensed under the AGPL version 3 or later.
#
# ctl/shared.nim:
## Shared procedures for potholectl.

import help

from ../lib import exit
from std/tables import `[]`

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

proc checkArgs*(args: seq[string], short, long: string): bool =
  for x in args:
    if short == x:
      return true
    if long == x:
      return true
  return false

const subsystems* = @["db"]
const commands* = @["db:init"]

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
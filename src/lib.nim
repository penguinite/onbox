# Copyright © Louie Quartz 2022
# Licensed under AGPL version 3 or later.
# lib.nim   ;;  Shared procedures/functions

# Required configuration file options to check for.
# Split by : and use the first item as a section and the other as a key
const requiredConfigOptions*: seq[string] = @[
  "db:type"
]

# Debugging procedure
proc error*(str: string, caller: string = ""): bool {.discardable.} =
  var newcaller = caller
  if len(newcaller) <= 0:
    try:
      newcaller = $getFrame().procname
    except:
      newcaller = "Unknown"
  var toBePrinted = "(" & newcaller & "): " & str
  stderr.writeLine(toBePrinted)
  writeStackTrace()
  quit(1)

# Also known as, error() for procedures without side effects (Aka. functions)
func err*(str: string, caller: string = "Unknown"): bool {.discardable.} = 
  var toBePrinted = "(" & caller & "): " & str
  debugEcho(toBePrinted)

  # Lie to the compiler to write a stacktrace.
  {.cast(noSideEffect).}:
    writeStackTrace()
  quit(1)

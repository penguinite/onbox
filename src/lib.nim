# Copyright © Louie Quartz 2022
# Licensed under AGPL version 3 or later.
# lib.nim   ;;  Shared procedures/functions

# For JSON datatype in Post definition.
#from std/json import JsonNode

# Required configuration file options to check for.
# Split by ":" and use the first item as a section and the other as a key
const requiredConfigOptions*: seq[string] = @[
  "database:type"
]

# An error or empty string
# Why use this? Well I dunno.
const null*: string = ""

# A set of unsafe characters, this filters anything that doesn't make a valid email.
const unsafeHandleChars*: set[char] = {'!',' ','"','#','$','%','&','\'','(',')','*','+',',',';','<','=','>','?','[','\\',']','^','`','{','}','|','~'}

# A set of charatcer that you cannot use
# when registering a local user.
const localInvalidHandle*: set[char] = {'@',':','.'}

# A set of whitespace characters
const whitespace*: set[char] = {' ', '\t', '\v', '\r', '\l', '\f'}

const version*: string = "0.0.1"
# User data type, which represents actual users in the database.
# Check data.nim for information on how this is validated
# Confusingly, "name" means display name and "handle" means
# actual username. It's too late to change this now sadly.
type 
  User* = object
    id*: string 
    handle*: string 
    name*: string 
    local*: bool 
    email*: string 
    bio*: string
    password*: string
    salt*: string

type
  UserRef* = ref User

# Debug function
# We want it to store 40 strings
# No more, no less.
var debugBuffer: seq[string];
var debugPrint: bool = false;
proc debug*(str: string, caller: string = $getFrame().procname) =
  if len(debugBuffer) > 40:
    debugBuffer.del(0)
  var toBeAdded = "!(" & caller & "): " & str
  debugBuffer.add(toBeAdded)
  if debugPrint:
    stderr.writeLine(toBeAdded)

proc exit*() {.noconv.} =
  quit(0)

# Debugging procedure
proc error*(str: string, caller: string = ""): bool {.discardable.} =
  var newcaller = caller
  if len(newcaller) <= 0:
    try:
      newcaller = $getFrame().procname
    except:
      newcaller = "Unknown"
  var toBePrinted = "Error: (" & newcaller & "): " & str
  stderr.writeLine("Printing stacktrace...")
  writeStackTrace()
  stderr.writeLine("Printing debug buffer...")
  for x in debugBuffer:
    stderr.writeLine(x)
  stderr.writeLine(toBePrinted)
  exit()

# Also known as, error() for procedures without side effects (Aka. functions)
func err*(str: string, caller: string = "Unknown"): bool {.discardable.} = 
  var toBePrinted = "(" & caller & "): " & str
  debugEcho(toBePrinted)

  # Lie to the compiler to write a stacktrace.
  {.cast(noSideEffect).}:
    writeStackTrace()
  exit()
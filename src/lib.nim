# Copyright © Louie Quartz 2022
# Licensed under AGPL version 3 or later.
# lib.nim   ;;  Shared procedures/functions

# Required configuration file options to check for.
# Split by : and use the first item as a section and the other as a key
const requiredConfigOptions*: seq[string] = @[
  "database:type"
]

# An error or empty string
# Why use this? Well I dunno.
const null*: string = ""

# A set of unsafe characters, this filters anything that doesn't make a valid email.
const unsafeHandleChars*: set[char] = {'!',' ','"','#','$','%','&','\'','(',')','*','+',',',';','<','=','>','?','[','\\',']','^','`','{','}','|','~'}

# A set of whitespace characters
const whitespace*: set[char] = {' ', '\t', '\v', '\r', '\l', '\f'}


# User data type, which represents actual users in the database.
# Check data.nim for information on how this is validated
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

# Post data type, which represents posts in the database.
# Check data.nim for information on how this is validated
type
  Post* = object
    id*: string
    sender*: string 
    written*: string 
    updated*: string
    recipients*: seq[string] 
    post*: string 

type
  UserRef* = ref User

type
  PostRef* = ref Post

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

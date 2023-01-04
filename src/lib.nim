# Copyright © Louie Quartz 2022-2023
# Licensed under AGPL version 3 or later.
# lib.nim   ;;  Shared procedures/functions

# For macro definition
from std/macros import newIdentNode, newDotExpr, strVal

# User data type, which represents actual users in the database.
# Check data.nim for information on how this is validated
# Confusingly, "name" means display name and "handle" means
# actual username. It's too late to change this now sadly.
#
# NOTE: If you are going to extend this  type then please
# edit the database schema in the exact order of User.
#
# EXTRA NOTE: If you are going to add a new datatype,
# maybe int for the number of followers, then please
# edit escape() and unescape() from data.nim and also edit
# addUser() and constructUserFromRow() from db.nim
# so they won't error out!
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
    is_frozen*: bool

type 
  Post* = object
    id*: string # A unique id.
    recipients*: seq[string] # A sequence of recipient's handles.
    sender*: string # aka attributedTo
    replyto*: string # Resource/Post person was replying to, 
    content*: string # The actual content of the post
    written*: string # A timestamp of when the Post was created
    updated*: string # A timestamp of when then Post was last edited
    local*:bool

# Special folders will be cached for speed
# Yes, we have to lie to the compiler again
# But it's fine! These will be initialized on
# startup and never touched again!
{.cast(gcsafe).}:
  var staticFolder* = "static/";
  var uploadsFolder* = "uploads/";
  var blogsFolder* = "blogs/";
  # I am not sure why but Pothole doesn't compile unless I do this
  # I am willing to put it down under "weird things that happen with jester"
  var debugBuffer {.threadvar.}: seq[string]; # A sequence to store debug strings in.
  var debugPrint: bool = true; # A boolean indicating whether or not to print strings as they come.

# Required configuration file options to check for.
# Split by ":" and use the first item as a section and the other as a key
const requiredConfigOptions*: seq[string] = @[
  "database:type"
]

# A set of unsafe characters, this filters anything that doesn't make a valid email.
const unsafeHandleChars*: set[char] = {'!',' ','"','#','$','%','&','\'','(',')','*','+',',',';','<','=','>','?','[','\\',']','^','`','{','}','|','~'}

# A set of charatcer that you cannot use
# when registering a local user.
const localInvalidHandle*: set[char] = {'@',':','.'}

# A set of whitespace characters
const whitespace*: set[char] = {' ', '\t', '\v', '\r', '\l', '\f'}

# App version
const version*: string = "0.0.2"

# How many items can be in debugBuffer before deleting some to save space
# Set to 0 to disable
const maxDebugItems: int = 40;

proc exit*() {.noconv.} =
  ## Exit function
  ## Maybe we can close the database on exit?
  quit(0)

proc debug*(str, caller: string) =
  ## Adds a string to the debug buffer and optionally
  ## prints it if debugPrint is set to true.
   
  # Delete an item from the debug buffer if it gets too big
  if maxDebugItems > 0:
    if len(debugBuffer) > maxDebugItems - 1:
      debugBuffer.del(0)

  # Actually add it to the debug buffer
  var toBeAdded = "(" & caller & "): " & str
  debugBuffer.add(toBeAdded)

  # Optionally print it. (If debugPrint is set to true)
  if debugPrint:
    stderr.writeLine(toBeAdded)

proc error*(str: string, caller: string = "Unknown"): bool {.discardable.} =
  ## Exits the program, writes a stacktrace and maybe print the debug buffer.
  var toBePrinted = "\nError: (" & caller & "): " & str
  stderr.writeLine("Printing stacktrace...")
  writeStackTrace()

  # Only print debug buffer if debugPrint is disabled
  # If this isn't here then the output gets too messy.
  if debugPrint == false:
    stderr.writeLine("Printing debug buffer...")
    for x in debugBuffer:
      stderr.writeLine(x)

  stderr.writeLine(toBePrinted)
  exit()

func len*(O: object): int =
  ## A procedure to get the total number of fields in any object
  var i: int = 0;
  for x in O.fields:
    inc(i)
  return i

macro get*(obj: object, fld: string): untyped =
  ## A procedure to get a field of an object using a string.
  ## Like so: user.get("local") == user.local
  newDotExpr(obj, newIdentNode(fld.strVal))


proc isEmptyOrWhitespace*(str: string): bool =
  ## A faster implementation of strutils.isEmptyOrWhitespace
  ## This is basically the same thing.
  for x in str:
    if x notin whitespace:
      return false
  return true

proc cleanString*(str: string): string =
  ## A procedure to clean a string of whitespacer characters.
  var startnum = 0;
  var endnum = len(str) - 1;
  
  while str[startnum] in whitespace:
    inc(startnum)

  while endnum >= 0 and str[endnum] in whitespace:
    dec(endnum)

  return str[startnum .. endnum]

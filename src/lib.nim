# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later.
# lib.nim:
## This module contains shared data across Pothole.
## It also contains useful procedures and functions that are
## used across the app.
## 
## Things like object definitions, string-handling functions
## and debugging functions fit well here but functions that are
## less commonly used or needed should be put elsewhere (Fx. the escape functions for the User & Post objects are rarely used so they are in separate modules.)
## 
## This module is very huge. Please try to put your stuff somewhere else.

# For macro definition
from std/macros import newIdentNode, newDotExpr, strVal

# User data type, which represents actual users in the database.
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
## Here are all of the fields in a user objects, with an explanation:
type 
  User* = ref object
    id*: string # An OID that represents the actual user (Db: blob primary key)
    handle*: string # A string containing the user's actual username (Db: varchar unique not null)
    name*: string # A string containing the user's display name (Db: varchar)
    local*: bool # A boolean indicating if this user is from this instance (Db: boolean)
    email*: string # A string containing the user's email (Db: varchar)
    bio*: string # A string containing the user's biography (Db: varchar)
    password*: string # A string to store a hashed + salted password (Db: varchar not null)
    salt*: string # The actual salt with which to hash the password. (Db: varchar not null)
    is_frozen*: bool #  A boolean indicating if the user is frozen/banned. (Db: )

# ActivityPub Object/Post
type 
  Post* = ref object
    id*: string # A unique id. (If its an internal post then just leave out the domain name, if it's external then add the full link)
    contexts*: seq[string] # A sequence of the contexts that this post has.
    recipients*: seq[string] # A sequence of recipient's handles.
    sender*: string # aka attributedTo, basically the person replying. (AP: Actor)
    replyto*: string # Resource/Post person was replying to,  
    content*: string # The actual content of the post
    written*: string # A timestamp of when the Post was created
    updated*: string # A timestamp of when then Post was last edited
    local*:bool # A boolean indicating whether or not the post came from the local server or external servers

{.cast(gcsafe).}:
  var debugBuffer: seq[string]; # A sequence to store debug strings in.

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

# App version
const version*: string = "0.0.2"

# How many items can be in debugBuffer before deleting some to save memory
# Set to 0 to disable
const maxDebugItems: int = 40;

const debugPrint: bool = true; # A boolean indicating whether or not to print strings as they come.

# A set of whitespace characters
const whitespace*: set[char] = {' ', '\t', '\v', '\r', '\l', '\f'}

func exit*() {.noconv.} =
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

proc error*(str,caller: string) =
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
  result = 0
  for x in O.fields:
    inc(result)

macro get*(obj: object, fld: string): untyped =
  ## A procedure to get a field of an object using a string.
  ## Like so: user.get("local") == user.local
  newDotExpr(obj, newIdentNode(fld.strVal))

func isEmptyOrWhitespace*(str: string): bool =
  ## A faster implementation of strutils.isEmptyOrWhitespace
  ## This is basically the same thing.
  for x in str:
    if x notin whitespace:
      return false
  return true

func cleanString*(str: string, charset: set[char] = whitespace): string =
  ## A procedure to clean a string of whitespace characters.
  var startnum = 0;
  var endnum = len(str) - 1;
  
  while str[startnum] in charset:
    inc(startnum)

  while endnum >= 0 and str[endnum] in charset:
    dec(endnum)

  return str[startnum .. endnum]

func cleanLeading*(str: string, charset: set[char] = whitespace): string =
  ## A procedure to clean the beginning of a string.
  var startnum = 0;
  
  while str[startnum] in charset:
    inc(startnum)

  return str[startnum .. len(str) - 1]

func cleanTrailing*(str: string, charset: set[char] = whitespace): string =
  ## A procedure to clean the end of a string.
  var endnum = len(str) - 1;

  while endnum >= 0 and str[endnum] in charset:
    dec(endnum)

  return str[0 .. endnum]

func `$`*(obj: User): string =
  ## Turns a User object into a human-readable string
  result.add("(")
  for key,val in obj[].fieldPairs:
    result.add("\"" & key & "\": \"" & $val & "\",")
  result = result[0 .. len(result) - 2]
  result.add(")")

func `$`*(obj: Post): string =
  ## Turns a Post object into a human-readable string
  result.add("(")
  for key,val in obj[].fieldPairs:
    result.add("\"" & key & "\": \"" & $val & "\",")
  result = result[0 .. len(result) - 2]
  result.add(")")


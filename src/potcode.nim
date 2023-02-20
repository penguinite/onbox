# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later.
# parser.nim  ;;  A procedure to parse Potcode.

## This module provides an easy to use interface
## for the reference implementation of the Potcode parser.
## This module heavily depends on Pothole modules (user, db, post, lib, conf)
## Heavy modifications would be needed to port this somewhere else.
## 
## Ie. it's called "Potcode" for a reason... It's for Pothole :P

{.experimental: "codeReordering".}


## This module is very much W.I.P

# From pothole
import lib, conf, db

# From standard library
import std/tables
import std/strutils except isEmptyOrWhitespace

# Basically whitespace from lib.nim but with '{' and '}' added in.
const badCharSet*: set[char] = {' ', '\t', '\v', '\r', '\l', '\f',';', '{', '}'}

func numOfDigits(key: int): int =
  result = 0
  for x in $key:
    inc(result)

func replace(str: string, key: int, val: string): string =
  var i = -1;
  var digits = numOfDigits(key);
  var doneX: int = 0;
  result = ""
  for ch in str:
    inc(i)
    if doneX != 0:
      inc(doneX)
      if doneX < digits + 6:
        continue
    else:
      if ch == '$':
        if $(ch & str[i + 1] & str[i + 2]) == "$((":
          # We have a candidate!
          if str[i + 3..i + 2 + digits] == $key:
            # We have a winner!
            inc(doneX)
            result.add(val)
            continue

    result.add(ch) # Add whatever we have, to the result.
  return result

func trimFunction(oldcmd: string): seq[string] =
  ## Trim a function into separate parts...
  ## This will return a sequence where the first item is the actual command
  ## and any other items are the arguments to that command
  ## A sequence with no items means that the function is invalid.
  ## 
  ## Example:
  ## trimFunction(":Start = Post;") -> @["start","post"]
  
  var cmd = oldcmd.cleanString(badCharSet)

  if not cmd.startsWith(":"):
    return @[]

  cmd = cmd[1 .. len(cmd) - 1] # Remove ":"

  var cmdsplit = cmd.split("=")

  for x in cmdsplit:
    result.add(cleanString(x, badCharSet))

  return result

# A list of possible instance values with the type string (or anything that isn't sequence)
var instanceScopeStr: seq[string] = @[
  "name","summary","description","uri","version","email","users","posts","maxchars"
]

# A list of possible instance values with the type of sequence
var instanceScopeSeqs: seq[string] = @[
  "rules"
]

proc isSeq(obj: string): bool =
  ## A function to check if a object is a sequence.
  ## You can use this to check for a string too. just check for the opposite result.
  if obj in instanceScopeSeqs:
    return true
  return false

#! This comment marks the parseInternal region. Procedures here are custom to the 
#! parseInternal procedure

proc getInstance(obj: string): string = 
  ## This is an implementation of the get() function.
  ## it parses things like {{ $Version }}
  ## This returns things related to the Instance scope.
  var cmd = obj
  if obj[0] == '$':
    cmd = obj[1 .. len(obj) - 1]
  case cmd:
    of "name":
      return conf.get("instance","name")
    of "summary":
      return conf.get("instance","description").split(".")[0]
    of "description":
      return conf.get("instance","description")
    of "uri":
      return conf.get("instance","uri")
    of "version":
      if conf.exists("web","show_version"):
        if conf.get("web","show_version") == "true":
          return lib.version
    of "email":
      if conf.exists("instance","email"):
        return conf.get("instance","email")
    of "users":
      return $db.getTotalUsers()
    of "posts":
      return $db.getTotalPosts()
    of "maxchars":
      if conf.exists("instance","max_chars"):
        return conf.get("instance","max_chars")
    else:
      return ""
  
  # Return nothing as a last resort
  return ""

proc getInstanceSeq(obj: string): seq[string] =
  ## Similar to getInstance, but this is used for sequences
  var cmd = obj
  if obj[0] == '$':
    cmd = obj[1 .. len(obj) - 1]
  case cmd:
    of "rules":
      if conf.exists("instance","rules"):
        return conf.split(get("instance","rules"))
    of "admins":
      return db.getAdmins()
    else:
      return @[]
  
  # Return nothing as a last resort
  return @[]

proc hasInternal(obj: string): bool = 
  ## This is an implemention of the Has() function
  ## But this should only be used for Internal pages.
  if isSeq(obj):
    if len(getInstanceSeq(obj)) < 0:
      return false
  else:
    if isEmptyOrWhitespace(getInstance(obj)):
      return false
  return true

func endInternal(blocks: OrderedTable[int, int], blockint: int): bool =
  ## This is an implemention of the End() function
  ## But this should only be used for Internal pages.
  if len(blocks) > 0:
    if blocks.hasKey(blockint):
      return true
    else:
      return false
  else:
    return false
  return true

proc parseInternal*(input:string): string =
  ## This is a watered down version of the parse() command that does not require User or Post objects
  ## It can be used to parse relatively simple pages, such as error pages and non-user pages (Instance rules fx.)
  
  var strings: seq[string] = @[] # A sequence that holds *all* strings.
  var table = initOrderedTable[int, string] # This holds all the context clues for the third stage of the parser.
  var parsingFlag = false; # A flag indicating whether we are currently parsing a command.
  var parsingFlagPrev = false; # A flag that stores the previous state of parsingFlag.
  var newcmd = ""; # A string for storing the command we are building.
  var newstr = ""; # A string for storing everything else.
  var i: int; # A variable for storing where we are currently in the string.

  for line in input.splitLines:
    i = -1;
    if "{{" in line and "}}" in line:
      for ch in line:

        if not parsingFlag and parsingFlagPrev:
          continue # Skip next char after done parsing
        if parsingFlag and not parsingFlagPrev:
          continue # Skip first char after parsing

        inc(i)
        if ch == '}':
          if line[i + 1] == '}':
            if len(newcmd) > 0:
              strings.add(cleanString(newcmd))

            newcmd = ""
            parsingFlag = false
            parsingFlagPrev = true
            continue

        if ch == '{':
          if line[i + 1] == '{':
            # Command starts here
            # Let's first push newstr to strings.
            if len(newstr) > 0:
              strings.add(cleanString(newstr))
              newstr = ""

            parsingFlagPrev = false
            parsingFlag = true
            continue

        if parsingFlag:
          newcmd.add(ch)
          continue
        else:
          newstr.add(ch)
      
      # Push newstr to strings at the end
      if len(newstr) > 0:
        strings.add(cleanString(newstr))
        newstr = ""
    else:
      strings.add(cleanString(line))
  
  

  return ""
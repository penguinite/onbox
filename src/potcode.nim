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
const badCharSet*: set[char] = {'\t', '\v', '\r', '\l', '\f',';', '{', '}'}

func numOfDigits(key: int): int =
  result = 0
  for x in $key:
    inc(result)

func replace(str: string, key: int, val: string): string =
  ## This function searches for the first occurence of key
  ## in str and it replaces it with val.
  ## This is way faster than the strutils/replace function
  ## which replaces all occurences.
  # This was useful in the previous version of the parser
  # But now that we parse line by line and sentence by sentence.
  # I think it's best that we
  # TODO: Deprecate this function
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

func trimFunction*(oldcmd: string): seq[string] =
  ## Trim a function into separate parts...
  ## This will return a sequence where the first item is the actual command
  ## and any other items are the arguments to that command
  ## A sequence with no items means that the function is invalid.
  ## 
  ## Example:
  ## trimFunction(":Start = Post;") -> @["start","post"]
  ## trimFunction(":ForEach(i) = $Attachments;") -> @["foreach","i","$attachments"]
  
  var cmd = oldcmd.cleanString(badCharSet)

  if not cmd.startsWith(":"):
    return @[]

  cmd = cmd[1 .. len(cmd) - 1] # Remove ":"

  result = @[]
  var store = ""
  var equalFlag = false;
  for ch in cmd:
    if not equalFlag:
      if ch == '(' or ch == ')':
        if not isEmptyOrWhitespace(store):
          result.add(cleanString(store))
        store = ""
        continue

      if ch == '=':
        equalFlag = true
        if not isEmptyOrWhitespace(store):
          result.add(cleanString(store))
        store = ""
        continue
    store.add(ch)
      

  # Push it to the end
  if store.endsWith(";"):
    store = store[0 .. len(store) - 2]

  if not isEmptyOrWhitespace(store):
    result.add(cleanString(store))
  store = ""
    
  return result


# A list of possible instance values with the type of sequence
var instanceScopeSeqs: seq[string] = @[
  "rules","admins"
]

proc isSeq(oldobj: string): bool =
  ## A function to check if a object is a sequence.
  ## You can use this to check for a string too. just check for the opposite result.
  var obj = oldobj
  if obj[0] == '$' or obj[0] == '#' or obj[0] == '.':
    obj = obj[1 .. len(obj) - 1]
  if obj in instanceScopeSeqs:
    return true
  return false

#! This comment marks the parseInternal region. Procedures here are custom to the 
#! parseInternal procedure

proc getInstance(obj: string): string = 
  ## This is an implementation of the get() function.
  ## it parses things like $Version
  ## This returns things related to the Instance scope.
  var cmd = obj
  if obj[0] == '$':
    cmd = obj[1 .. len(obj) - 1]
  echo("caught: ", conf.get("instance","name"))
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
      return "" ## Unknown object, return nothing
  
  # Return nothing as a last resort
  return ""

proc getInstanceSeq(obj: string): seq[string] =
  ## Similar to getInstance, but this is used for sequences
  ## Use isSeq() before using either this function or getInstance
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
  var sequence: seq[string] = @[] # A sequence that holds *all* strings.
  for line in input.splitLines:
    if isEmptyOrWhitespace(line):
      continue # Skip since line is mostly empty anyway.

    if line.contains("{{"):
      # Switch to character by character parsing
      var i: int = 0; # A variable for storing what character we currently are at in the line.  
      var noncommand:string = ""; # A string to hold anything that isn't a command
      var command:string = ""; # A string to hold anything that is a command.
      for ch in line:
        inc(i)
        # Instead of storing even more booleans
        # We just check the length of command.
        # If it's higher than zero then it means we
        # are parsing something
        if len(command) > 0:
          if ch == '}': # Check for end of command.
            # We're at the end
            if not isEmptyOrWhitespace(command):
              sequence.add(command) # Only add command if it has something.
            command = "" # Otherwise just clear this out...
          else:
            command.add(ch)
          continue

        if ch == '}' and len(command) == 0 and len(noncommand) == 0:
          # We can conclude that a command has *just* been added to the
          # sequence var
          continue # Skip this then, we don't need extra "}" chars in our sequence

        if ch == '{':
          if len(line) < i:
            continue # End of input

          if line[i] == '{':
            # Start command.

            if not isEmptyOrWhitespace(noncommand): # Check that the noncommand isn't empty
              sequence.add(cleanString(noncommand)) # Push noncommand to sequence
            noncommand = ""
            command = "{" # Add anything to trigger the len(command) > 0 check
            continue

        if len(command) == 0:
          noncommand.add(ch)
          continue
      # Push noncommand to sequence at the end.
      if len(noncommand) > 0:
        sequence.add(cleanString(noncommand))
    else:
      sequence.add(cleanString(line))
  
  var maxNestLevel = 3; # Maximum nesting level. Configured in [web]/potcode_max_nests
  if conf.exists("web","potcode_max_nests"):
    maxNestLevel = parseInt(conf.get("web","potcode_max_nests"));

  var
    parsingBlock = 0 # 0 means we aren't parsing a block, anything else is the id of the command that started the block
    parsingLoop = 0 # 0 means we aren't parsing a loop, anything else is the id of the command that started the loop
    nestLevel = 0 # This number stores how much we have nested so far.
    blocks: seq[int] = @[] # This stores all the blocks we currently made.
    i = -1; # Good old i as a counter variable.

  for item in sequence:
    inc(i)
  
  return result
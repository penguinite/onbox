# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later.
# parser.nim  ;;  A procedure to parse Potcode.

## This module provides an easy to use interface
## for the reference implementation of the Potcode parser.
## This module heavily depends on Pothole modules (user, db, post, lib, conf)
## Heavy modifications would be needed to port this somewhere else.
## 
## Ie. it's called "Potcode" for a reason... It's for Pothole :P

## This module is very much W.I.P

# From pothole
import lib, conf, db

# From standard library
import std/tables
import std/strutils except isEmptyOrWhitespace

# Basically whitespace from lib.nim but with '{' and '}' added in.
const badCharSet*: set[char] = {' ', '\t', '\v', '\r', '\l', '\f',';', '{', '}'}

#const advancedCommands = @["foreach","displaygenactivity","end","howmany","shorten","externaluser","has","isupdated","isreply","isexternal","start","setpostlimit","version"]

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
      if doneX < digits + 4:
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

func parsePostLimit(cmd: string): int =
  var newcmd = trimFunction(cmd)

  if len(newcmd) > 1:
    return parseInt(newcmd[1])
  else:
    return 15 # Return default limit

func parsePostBlock(cmd: string, previousState: bool = false, blocks: seq[string] = @[]): bool =
  ## This command basically parses a command and checks if it ends or starts the Post block.
  ## This way, we can store the Post block in a separate variable that we will handle and generate repeatedly.
  
  var newcmd = trimFunction(cmd)
  var len = len(newcmd) - 1

  debugecho(newcmd)

  if len(newcmd) == 0:
    return false # Invalid command?


  if newcmd[0] == "start":
    # Start command detected
    discard # TODO: Finish this

  if newcmd[0] == "end":
    # End command detected
    discard # TODO: Finish this
  
  # At this point, it's safe to return false.
  return false

# A list of possible instance values with the type string (or anything that isn't sequence)
var instanceScopeStr: seq[string] = @[
  "name","summary","description","uri","version","email","users","posts","maxchars"
]

# A list of possible instance values with the type of sequence
var instanceScopeSeqs: seq[string] = @[
  "rules"
]

# These will be filled out later.
var userScopeStr: seq[string] = @[]
var userScopeSeqs: seq[string] = @[]
var postScopeStr: seq[string] = @[]
var postScopeSeqs: seq[string] = @[]

proc isSeq(obj: string): bool =
  ## A function to check if a object is a sequence.
  ## You can use this to check for a string too. just check for the opposite result.
  if obj in instanceScopeSeqs:
    return true
  if obj in userScopeSeqs:
    return true
  if obj in postScopeSeqs:
    return true
  return false


#! This has been set aside for a long time so
# TODO: Review the existing code and finish this feature.
proc parse*(input: string, user: User, post: seq[Post], context: string, extra: string = ""): string =
  
  ## Generic parse procedure for Potcode.
  # Params explained:
  # input: A string containing the file to parse. (The actual file's contents)
  # user: A User object of the user we are trying to parse for.
  # seq[Post]: a sequence of Post objects that can be found in the database.
  # context: What we are trying to parse, and what purpose does it serve. Are we parsing a user profile or a user's favorite posts? list.html,  error.html or some other file??? user for user.html, error for error.html, list for list.html and post for post.html
  
  var cmdtable: OrderedTable[int,string] = initOrderedTable[int, string]() # This stores all commands and their identifiers.
  var commandsInPostBlock: seq[int] = @[] # This stores the identifiers (integer ids) of the commands that are in the post block
  var parsingPostBlock: bool = false; # A boolean indicating whether or not we are parsing commands for a post block.
  
  var parsingCmd: bool = false; # A boolean indicating whether or not we are currently parsing a command.
  var newcmd = "" # A string to store the command currently being parsed
  var i = -1; # We have to set it to -1 because when the loop starts it will automatically plus it once to bring it 0.
              # And also, sequences in nim (including strings, which are just sequences of bytes) begin with 0.

  # Loop over every character
  for ch in input:
    inc(i)

    # If we are currently in the middle of parsing a command then
    # just check if its '}' and if it is then do the same +1 check
    # we did previously with '{'
    # and end the command if its true.
    if parsingCmd == true:

      if ch == '}':
        if len(input) < i + 1:
          continue # End of file/string

        if input[i + 1] == '}':
          parsingCmd = false # Disable parsingCmd mode.
          cmdtable[len(cmdtable)] = newcmd # Add command

          # So, before we do anything else
          # Let's check if we are in a post block
          # Post blocks are special, in that, they are generated. So we need to store a separate string and table
          parsingPostBlock = parsePostBlock(newcmd, parsingPostBlock)
          if parsingPostBlock == true:
            commandsInPostBlock.add(len(cmdtable)) # Add command identifier to this list so we can parse it later.
          else:
            result.add("$((" & $len(cmdtable) & "))") # Add marker that we can easily replace in the end.
          newcmd = "" # Empty this
          
      else:
        newcmd.add(ch)
      continue


    # Here we check for '{', and if the next character
    # is also a '{', if that's the case then we enable
    # parsingCmd
    if ch == '{':
      
      if len(input) < i + 1:
        continue # End of file/string

      if input[i + 1] == '{':
        parsingCmd = true
        continue # We have a cmd!
    

    # One last check so we dont get any ugly '}' chars
    if ch == '}':
      if not len(input) > i - 1:
        continue

      if input[i - 1] == '}':
        continue

    # Add whatever we have to the end result
    result.add(ch)

  return result

#! This comment marks the parseInternal region. Procedures here are custom to the 
#! parseInternal procedure

proc getInstance(obj: string): string = 
  ## This is an implementation of the get() function.
  ## it parses things like {{ $Version }}
  ## This returns things related to the Instance scope.
  case obj:
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
  case obj:
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
  if 

proc endInternal(blocks: seq[int], obj: string = ""): bool =
  return true # TODO: Finish this

proc parseInternal*(input:string): string =
  ## This is a watered down version of the parse() command that does not require User or Post objects
  ## It can be used to parse relatively simple pages, such as error pages and non-user pages (Instance rules fx.)
  
  var cmdtable: OrderedTable[int,string] = initOrderedTable[int, string]() # This stores all commands and their identifiers.
  
  var parsingCmd: bool = false; # A boolean indicating whether or not we are currently parsing a command.
  var newcmd = "" # A string to store the command currently being parsed
  var i = -1; # We have to set it to -1 because when the loop starts it will automatically plus it once to bring it 0. And also, sequences in nim (including strings, which are just sequences of bytes) begin with 0.

  # Loop over every character
  for ch in input:
    inc(i)

    # If we are currently in the middle of parsing a command then
    # just check if its '}' and if it is then do the same +1 check
    # we did previously with '{'
    # and end the command if its true.
    if parsingCmd == true:
      if ch == '}':
        if len(input) < i + 1:
          continue # End of file/string

        if input[i + 1] == '}':
          parsingCmd = false # Disable parsingCmd mode.
          cmdtable[len(cmdtable) + 1] = newcmd # Add command
          result.add("$((" & $(len(cmdtable)) & "))") # Add marker that we can easily replace in the end.
          newcmd = "" # Empty this
          
      else:
        newcmd.add(ch)
      continue


    # Here we check for '{', and if the next character
    # is also a '{', if that's the case then we enable
    # parsingCmd
    if ch == '{':
      
      if len(input) < i + 1:
        continue # End of file/string

      if input[i + 1] == '{':
        parsingCmd = true
        continue # We have a cmd!
    

    # One last check so we dont get any ugly '}' chars
    if ch == '}':
      if not len(input) > i - 1:
        continue

      if input[i - 1] == '}':
        continue

    # Add whatever we have to the end result
    result.add(ch)

  var blocks: seq[int] = @[]; # A sequence for storing blocks.
  for key,oldvalue in cmdtable.pairs:
    var value = toLower(oldvalue.cleanString(badCharSet))
    echo("(Key: \"" & $key & "\", Value: \"" & value & "\")")
    if value.startsWith(":"):
      var trimSeq = trimFunction(value)
      # Let's do basic command checking
      case trimSeq[0]:
        of "has":
          if hasInternal(trimSeq[1]):
            blocks.add(key)
          else:
            continue
        of "end":
          var temp: bool = false;
          if len(trimSeq) > 1:
            temp = endInternal(blocks,trimSeq[1])
          else:
            temp = endInternal(blocks) # The most recent block should be assumed.
          
          if temp:
            discard blocks.pop()

        else:
          result = result.replace("$((" & $key & "))","! Unknown function " & value)
    else:
      #[if value[0] == '$':
        value = value[1 .. len(value) - 1]
      if isSeq(value):
        result = result.replace(key, getInstanceSeq(value)[0])
      else:
        result = result.replace(key, getInstance(value))
        echo(getInstance(value))
        echo(result)]#
        continue
  

  return result
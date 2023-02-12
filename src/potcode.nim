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

import tables
import lib

import strutils except isEmptyOrWhitespace

# Basically whitespace from lib.nim but with '{' and '}' added in.
const badCharSet*: set[char] = {' ', '\t', '\v', '\r', '\l', '\f',';', '{', '}'}

#const advancedCommands = @["foreach","displaygenactivity","end","howmany","shorten","externaluser","has","isupdated","isreply","isexternal","start","setpostlimit","version"]

func trimFunction(oldcmd: string): seq[string] =
  ## Trim a function into separate parts...
  ## This will return a sequence where the first item is the actual command
  ## and any other items are the arguments to that command
  ## A sequence with no items means that the function is invalid.
  ## 
  ## Example:
  ## trimFunction(":Start = Post;") -> @["start","post"]
  
  var cmd = toLower(oldcmd.cleanString(badCharSet))

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
  

proc parse*(input: string, user: User, post: seq[Post], context: string, extra: string = ""): string =
  ## Generic parse procedure for Potcode.
  # Params explained:
  # input: A string containing the file to parse. (The actual file's contents)
  # user: A User object of the user we are trying to parse for.
  # seq[Post]: a sequence of Post objects that can be found in the database.
  # context: What we are trying to parse, and what purpose does it serve. Are we parsing a user profile or a user's favorite posts? list.html,  error.html or some other file??? user for user.html, error for error.html, list for list.html and post for post.html
  
  var cmdtable: Table[int,string] = initTable[int, string]() # This stores all commands and their identifiers.
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

proc parseInternal*(input:string): string =
  ## This is a watered down version of the parse() command that does not require User or Post objects
  ## It can be used to parse relatively simple pages, such as error pages and non-user pages (Instance rules fx.)
  
  var cmdtable: Table[int,string] = initTable[int, string]() # This stores all commands and their identifiers.
  
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
          cmdtable[len(cmdtable)] = newcmd # Add command
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

  for key,oldvalue in cmdtable.pairs:
    var value = oldvalue.cleanString(badCharSet)



  return result
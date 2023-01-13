# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later.
# parser.nim  ;;  A procedure to parse Potcode.

## This module provides an easy to use interface
## for the reference implementation of the Potcode parser.
## This module heavily depends on data, db and nim and is specifically intended to be used in Pothole.
## Heavy modifications would be needed to port this somewhere else.
## 
## Ie. it's called "Potcode" for a reason... It's for Pothole :P

import tables
import lib, data, db

import strutils except isEmptyOrWhitespace

# A fake user and post 
var user = User()
var post = Post()

const file = staticRead("../assets/user.html")
#const file = "Hello I'm {{ .Name }}"

# Basically whitespace from lib.nim but with '{' and '}' added in.
const badCharSet*: set[char] = {' ', '\t', '\v', '\r', '\l', '\f', '{', '}'}
const advancedCommands = @["foreach","displaygenactivity","end","howmany","shorten","externaluser","has","isupdated","isreply","isexternal","start","setpostlimit","version"]


# The Has function
proc has(cmd: string, user: User, post: Post, scope: string): bool =

  return false

# The first stage of parsing is 
# getting every command, cleaning it and 
# adding it to a sequence.
# The second stage is basic parsing.
# We replace all the easy parts and then
# We move on to the third step which is semantic/advanced parsing.
# Here we have to deal with loops, blocks and all sorts of crazy things.
# And it is the hardest part of the whole ordeal.
#
# Note: One thing I want to do is kinda make the parser use Nim functions.
# I write various commands as real Nim functions which then get used.
# The only problem is we need a way to synchronise posts inbetween procedures.
# We could pass them together as a part of the command.
#
# Extra note: In the first stage we add each command to a table and replace it
# in memory with a marker, that we can easily replace later on when we are done parsing everything.

# input: A string containing the file to parse. (The actual file's contents)
# user: A User object of the user we are trying to parse for.
# seq[Post]: a sequence of Post objects that can be found in the database.
# context: What we are trying to parse, and what purpose does it serve. Are we parsing a user profile or a user's favorite posts? list.html, error.html or some other file??? user for user.html, error for error.html, list for list.html and post for post.html
proc parse(input: string, user: User, post: seq[Post], context: string): string =
  # This array will store a list of commands.
  # They will be processed one by one later on.
  
  var cmdtable: Table[int,string] = initTable[int, string]()
  
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

  # Second stage.
  # First we want to cleanup all commands
  for k,v in cmdtable.pairs:
    cmdtable[k] = cleanString(v,badCharSet)

  # Let's divide these commands into two types.
  # The first one will be parsed right now.
  # The other one will be analyzed right now and executed later.
  # This only stores the markers!
  var advanced: seq[int] = @[]
  var simple: seq[int] = @[]
  
  if len(cmdtable) < 1:
    return result # Exit early to skip this whole chunk of code.
                  # This speeds up parsing for files that do not have commands.

  for k,v in cmdtable.pairs:
    var cmd = v.toLower()
    if cmd.startsWith(':'):
      advanced.add(k)
      continue

    for x in advancedCommands:
      if cmd.startsWith(x):
        advanced.add(k)
        continue
      continue
    
    simple.add(k) # It's probably a simple command

  echo("Simple: ", simple)
  echo("Advanced: ", advanced)

  var scope = ""; # This variable stores the scope of the command we are currently parsing.
  var blocks: seq[int] = @[]; # This variable stores a list of current blocks, we terminate them as we process them.

  # Start parsing advanced commands
  # Here comes the really long complex code bits.
  
  i = -1
  if len(advanced) > 0:
    for y in advanced:
      inc(i)
      var cmd = toLower(cmdtable[y])

  # Start parsing simple commands
  
  if len(simple) > 0: # Only parse if there are any commands, otherwise it's a waste.
    for i in simple:
      var cmd = toLower(cmdtable[i])
      if cmd.startsWith("#"):
        scope = "post"
        continue
      if cmd.startsWith("."):
        scope = "user"
        continue
      if cmd.startsWith("$"):
        scope = "instance"
        continue

  return result

discard parse(file,user,post,"user")
#echo(parse(file))
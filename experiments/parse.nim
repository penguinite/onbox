import strutils, tables
import ../src/lib, ../src/data


# A fake user and post 
var user = User()
var post = Post()

const file = staticRead("../assets/user.html")
#const file = "Hello I'm {{ .Name }}"

# Basically whitespace from lib.nim but with '{' and '}' added in.
const badCharSet*: set[char] = {' ', '\t', '\v', '\r', '\l', '\f', '{', '}'}

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
proc parse(input: string): string =
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

  echo(cmdtable)
  return result

#discard parse(file)
echo(parse(file))
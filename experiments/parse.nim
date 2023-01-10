import strutils
import ../src/lib, ../src/data


# A fake user and post 
var user = User()
var post = Post()


#const file = staticRead("../assets/user.html")
const file = "Hello I'm $( .Name )"

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
#
proc parse(input: string): string =
  # This array will store a list of commands.
  # They will be processed one by one later on.
  # 
  var cmdseq: seq[string] = @[]
  
  var parsingCmd: bool = false;
  var newcmd = ""
  var i = 0

  # Loop over every character
  for ch in input:
    inc(i)
    
    # Check if character is dollar sign, if it is then
    # we check if the next character is "Open parenthesis"
    # And that tells us whether we have a real command or
    # something else.
    if ch == '$':
      if i + 1 > len(input):
        continue # End of file/string, just skip.

      if input[i + 1] == '(':
        parsingCmd = true
        continue

    if parsingCmd == true:
      if ch == ')':
        parsingCmd = false
        cmdseq.add(newcmd)
        
        # We can use this to replace our markers with the output of the commands at the very end.
        result.add("$((" & $len(cmdseq) & "))")
        newcmd = ""
      else:
        newcmd.add(ch)
      continue

    # At the end, we want to add whatever character we have to 
    # the end-result
    result.add(ch)

  # Second stage.
  # First we want to cleanup all commands
  echo(cmdseq)
  i = 0;
  for x in cmdseq:
    inc(i)
    cmdseq[i] = clean(x)

  echo(cmdseq)
  return result

#discard parse(file)
echo(parse(file))
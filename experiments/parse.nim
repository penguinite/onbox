import strutils, strscans

const file = staticRead("../assets/user.html")

# whitespace cleaning apparatus
func clean(str: string, leading, trailing: bool = true): string = 
  var newstr = str
  var startnum = 0;
  var endnum = len(newstr) - 1;

  if leading:
    while str[startnum] in Whitespace: 
      inc(startnum)

  if trailing:
    while endnum >= 0 and str[endnum] in Whitespace: 
      dec(endnum)

  return 

# How do I wanna implement the Potcode parser?
#
# So I came up with something...
# Potcode is really just Nim procedures wrapped up
# in a simple language.
#
# So Fx. End, Has, ForEach can all be implemented
# as functions and we replace the command "{{ ... }}"
# with their output
#
# Of course we also use variables to store information
# such as blocks, scopes and whatnot.
var blocks = @["main"]
var scope = ""
var cmdarray: seq[string] = @[]

# This command takes a string with commands and converts it
# into a format that can be easily replaced.
# Something like this:
  # before: <h1>{{ .Name }}</h1>
  # after: <h1>#{{0}}</h1>
# The cmd will be put into a string array
# and the result will be parsed and stored
# in that same array.
#
# And then when it comes time to finally render the page
# we can use strutils.replace() to replace any and all 
# occurences of #{{NUM}} with the string in the cmd array.
proc parse(input: string): string =
  
  var newinput = "";
  for x in input.splitLines:
    if input.contains("{{") or input.contains("}}"):
      # let's try to get only the command and split the rest
      # first see if there is one command or multiple ones in
      # the current line.
      var cmdseq = input.split("{{")
      if cmdseq.len() > 1:
        # There are multiple commands
        discard
      else:
        # There is only a single command on each line
          

    else:
      newinput.add(input)
  return newinput

discard parse(file)
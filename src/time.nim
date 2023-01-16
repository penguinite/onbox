# Very basic wrapper for std/times
# Please store the date as is and just use
# the decode() function provided here
# everytime you need to process the date.
## This is some of the worst code I ever wrote
## Time is an awful thing...

# This procedure returns two strings in a sequence
# the first one is the time with all of the buggy chars removed
# the second one is the ideal format you should use
#
# Just run times.parse() using these two values.
proc decode*(x: string): seq[string] = 
  var format = "YYYY-mm-dd:hh:mm:ss"
  var i = -1
  var skipThese = 0
  var timeToBe = ""

  for ch in x:
    inc(i)

    if skipThese != 0:
      dec(skipThese)
      continue
    
    # Remove T as it can error out in std/times parser
    if ch == 'T':
      timeToBe.add(":")
      continue
    
    # Skip the milliseconds...
    if ch == '.':
      var countflag = false
      for loop in 0 .. i:
        if countflag == true:
          inc(skipThese)
        if ch == '.':
          countflag = true
      continue
    
    # Remove Z since it can also bug out the std/times parser
    if ch == 'Z':
      continue

    # Finally add whats remaining to a string.
    timeToBe.add(ch)
  
  return @[timeToBe,format]
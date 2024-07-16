from std/strutils import Whitespace, `%`, toLowerAscii, startsWith

func isEmptyOrWhitespace*(str: string, charset: set[char] = Whitespace): bool =
  ## A faster implementation of strutils.isEmptyOrWhitespace
  ## This is basically the same thing.
  for ch in str:
    if ch notin charset:
      return false
  return true

func isEmptyOrWhitespace*(ch: char, charset: set[char] = Whitespace): bool =
  ## A faster implementation of strutils.isEmptyOrWhitespace
  ## This is basically the same thing.
  if ch notin charset:
    return false
  return true

func parseBool*(str: string): bool = 
  ## I'll have to add this because strutils.parseBool() does not have "t" and "f"
  ## And I think the reason for this inclusion was that db_postgres or something db-related was return "t" and "f" for booleans.
  ## And since parseBool() did not support this, it was messing up the entire database logic of pothole.
  ## TODO: Submit a PR to nim upstream to add "t" and "f" in parseBool()
  case str.toLowerAscii():
  of "y", "yes", "true", "1", "on", "t": return true
  of "n", "no", "false", "0", "off", "f": return false

func cleanString*(str: string, charset: set[char] = Whitespace): string =
  ## A procedure to clean a string of whitespace characters.
  var startnum = 0;
  var endnum = len(str) - 1;

  if len(str) < 1:
    return "" # Return nothing, since there is nothing to clean anyway

  while str[startnum] in charset:
    if startnum == high(str): return ""
    inc(startnum)

  while endnum >= 0 and str[endnum] in charset:
    if endnum == high(str): return ""
    dec(endnum)

  return str[startnum .. endnum]

func cleanLeading*(str: string, charset: set[char] = Whitespace): string =
  ## A procedure to clean the beginning of a string.
  var startnum = 0;

  while str[startnum] in charset:
    if startnum == high(str): return ""
    inc(startnum)

  return str[startnum .. len(str) - 1]

func cleanTrailing*(str: string, charset: set[char] = Whitespace): string =
  ## A procedure to clean the end of a string.
  var endnum = len(str) - 1;

  while endnum >= 0 and str[endnum] in charset:
    if endnum == high(str): return ""
    dec(endnum)

  return str[0 .. endnum]

proc smartSplit*(s: string, specialChar: char = '&'): seq[string] =
  ## A split function that is both aware of quotes and backslashes.
  ## Aware, as in, it won't split if it sees the specialCharacter surrounded by quotes, or backslashed.
  ## 
  ## Used in (and was originally written for) `pothole/routeutils.nim:unrollForm()`
  var
    quoted, backslash = false
    tmp = ""
  for ch in s:
    case ch:
    of '\\':
      # If a double backslash has been detected then just
      # insert a backslash into tmp and set backslash to false
      if backslash:
        backslash = false
        tmp.add(ch)
      else:
        # otherwise, set backslash to true
        backslash = true
    of '"', '\'': # Note: If someone mixes and matches quotes in a form body then we're fucked but it doesn't matter either way.
      # If a backslash was previously detected then
      # add double quotes to tmp instead of toggling the quoted flag
      if backslash:
        tmp.add(ch)
        backslash = false
        continue

      if quoted:
        quoted = false
      else:
        quoted = true      
    else:
      # if the character we are currently parsing is the special character then
      # check we're not in backslash or quote mode, and if not
      # then finally split.
      if ch == specialChar:
        if backslash or quoted:
          tmp.add(ch)
          continue

        result.add(tmp)
        tmp = ""
        continue
      
      # otherwise, just check for backslash and add it to tmp if it isn't backslashed.
      if backslash:
        continue
      tmp.add(ch)
  
  # If tmp is not empty then split!
  if tmp != "":
    result.add(tmp)

  # Finally, the good part, return result.
  return result

proc htmlEscape*(pre_s: string): string =
  ## Very basic HTML escaping function.
  var s = pre_s
  if s.startsWith("javascript:"):
    s = s[11..^1]
  if s.startsWith("script:"):
    s = s[7..^1]
  if s.startsWith("java:"):
    s = s[5..^1]

  for ch in s:
    case ch:
    of '<':
      result.add("&lt;")
    of '>':
      result.add("&gt;")
    else:
      result.add(ch)
from std/strutils import Whitespace, `%`, toLowerAscii

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
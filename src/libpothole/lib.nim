# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# lib.nim:
## This module contains shared data across the whole library.
## It also contains useful procedures and functions that are
## used across the entire library.
##
## This module pre-9f3077d used to store the User and Post definitions
## But these have been moved, and this module has been re-purposed.
## The User and Post definitions are now stored in pothole/user and pothole/post respectively.

# For macro definition
from std/macros import newIdentNode, newDotExpr, strVal

var debugBuffer: seq[string]; # A sequence to store debug strings in.

# App version
when defined(phVersion):
    const phVersion* {.strdefine.}: string = ""
else:
  const phVersion*: string = "0.0.2"
const version*: string = phVersion

# How many items can be in debugBuffer before deleting some to save memory
# Add -d:maxDebugItems=NUM and replace NUM with a number to customize this.
const maxDebugItems {.intdefine.}: int = 120;

# This boolean controls whether to print debug strings as they come
# Irregardless of whether this is set or not, error() will print the entire debugBuffer
# Add -d:debugPrint=BOOL and replace BOOL with true or false to customize this.
const debugPrint {.booldefine.}: bool = true

# A set of whitespace characters
const whitespace*: set[char] = {' ', '\t', '\v', '\r', '\l', '\f'}

proc exit*() {.noconv.} =
  quit(1)

proc debug*(str, caller: string) =
  ## Adds a string to the debug buffer and optionally
  ## prints it if debugPrint is set to true.
   
  # Delete an item from the debug buffer if it gets too big
  if len(debugBuffer) > maxDebugItems - 1:
    debugBuffer.del(0)

    # Actually add it to the debug buffer
  var toBeAdded = "(" & caller & "): " & str
  debugBuffer.add(toBeAdded)

  # Optionally print it. (If debugPrint is set to true)
  when debugPrint == true:
    stdout.writeLine(toBeAdded)

proc error*(str,caller: string) =
  ## Exits the program, writes a stacktrace and maybe print the debug buffer.
  stderr.writeLine("\nPrinting stacktrace...")
  writeStackTrace()

  # Only print debug buffer if debugPrint is disabled
  # If this isn't here then the output gets too messy.
  stderr.writeLine("\nPrinting debug buffer...")
    for x in debugBuffer:
      stderr.writeLine(x)

  stderr.writeLine("\nError (" & caller & "): " & str)
  quit(1)

macro get*(obj: object, fld: string): untyped =
  ## A procedure to get a field of an object using a string.
  ## Like so: user.get("local") == user.local
  newDotExpr(obj, newIdentNode(fld.strVal))

func isEmptyOrWhitespace*(str: string, charset: set[char] = whitespace): bool =
  ## A faster implementation of strutils.isEmptyOrWhitespace
  ## This is basically the same thing.
  for x in str:
    if x notin charset:
      return false
  return true

func cleanString*(str: string, charset: set[char] = whitespace): string =
  ## A procedure to clean a string of whitespace characters.
  var startnum = 0;
  var endnum = len(str) - 1;

  if len(str) < 1:
    return "" # Return nothing, since there is nothing to clean anyway
  
  while str[startnum] in charset:
    inc(startnum)

  while endnum >= 0 and str[endnum] in charset:
    dec(endnum)

  return str[startnum .. endnum]

func cleanLeading*(str: string, charset: set[char] = whitespace): string =
  ## A procedure to clean the beginning of a string.
  var startnum = 0;
  
  while str[startnum] in charset:
    inc(startnum)

  return str[startnum .. len(str) - 1]

func cleanTrailing*(str: string, charset: set[char] = whitespace): string =
  ## A procedure to clean the end of a string.
  var endnum = len(str) - 1;

  while endnum >= 0 and str[endnum] in charset:
    dec(endnum)

  return str[0 .. endnum]
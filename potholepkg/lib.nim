# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This file is part of Pothole.
# 
# Pothole is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Pothole is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Pothole. If not, see <https://www.gnu.org/licenses/>. 
#
# lib.nim:
## This module contains useful procedures and functions.
## Like for error reporting and whatnot. It also contains important
## contants for post-mortem debugging, version numbers, what kdf to use.
##
## This module pre-9f3077d used to store the User and Post type definitions
## but these have been moved, and this module has been re-purposed.
## The User and Post definitions are now stored in pothole/user and pothole/post respectively.

# For macro definition
from std/macros import newIdentNode, newDotExpr, strVal
from std/strutils import Whitespace, `%`

# App version
const phVersion* {.strdefine.}: string = "0.0.2" ## This constant allows you to customize the potholepkg version that is reported by default using compile-time-directives. Or else just default to the built-in embedded version. To customize the version, just add the following compile-time build option: `-d:phVersion=whatever`
const version*: string = phVersion ## This is basically just phVersion, but it's copied twice for readability purposes.

# A folder to save debugging data to.
const globalCrashDir* {.strdefine.}: string = "CAR_CRASHED_INTO_POTHOLE!"

const kdf* = 1 ## The latest Key Derivation Function supported by this build of potholepkg, check out the KDF section in the DESIGN.md document for more information.

when not defined(phNoLog):
  template log*(str: varargs[string, `$`]) =
    var msg = ""
    for s in str:
      msg.add(s)
    stdout.write("($#:$#): $#\n" % [instantiationInfo().filename, $instantiationInfo().line, msg])
else:
  template log*(msg: varargs[string, `$`]) = return

template error*(str: varargs[string, `$`]) =
  ## Exits the program, writes a stacktrace and thats it.
  stderr.write("\nPrinting stacktrace...\n")
  writeStackTrace()  

  var msg = ""
  for s in str:
    msg.add(s)
  stderr.write("\n[ERROR] ($#:$#): $#\n" % [instantiationInfo().filename, $instantiationInfo().line, msg])
  quit(1)

macro get*(obj: object, fld: string): untyped =
  ## A procedure to get a field of an object using a string.
  ## Like so: user.get("local") == user.local
  newDotExpr(obj, newIdentNode(fld.strVal))

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

func int64ToInt*(num: int64): int =
  ## The only reason this procedure exists at all is because tiny_sqlite's intVal macro gets us a int64, not a regular int.
  ## which somehow breaks everything so we need this to convert from int64 to int
  return num.int
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

# TODO: Remove this module once everything has been properly migrated.
 
 # A folder to save debugging data to.
const globalCrashDir* {.strdefine.}: string = "CAR_CRASHED_INTO_POTHOLE!"

# App version and other useful data.
const
  phVersion* {.strdefine.}: string = "0.0.2" ## To customize the version, compile with the option: `-d:phVersion=whatever`
  phMastoCompat* {.strdefine.}: string = "wip" ## The level of API compatability, this option doesn't do anything. It's just reported in the API.
  phSourceUrl* {.strdefine.}: string = "https://github.com/penguinite/pothole" ## To customize the source URL, compile with the option: `-d:phSourceUrl="Link"`

when defined(phNoLog):
  template log*(msg: varargs[string, `$`]) = return
  template error*(msg: varargs[string, `$`]) = quit(1)
else:
  from std/strutils import Whitespace, `%`, toLowerAscii, join
  from std/times import now, utc, format
  
  template log*(str: varargs[string, `$`]) =
    stdout.write("[$#] ($#:$#): $#\n" % [now().utc.format("yyyy-mm-dd hh:mm:ss"), instantiationInfo().filename, $instantiationInfo().line, str.join])

  template error*(str: varargs[string, `$`]) =
    ## Exits the program with an error messages and a stacktrace.
    stderr.write("\n!ERROR! [$#] ($#:$#): $#\n" % [now().utc.format("yyyy-mm-dd hh:mm:ss"), instantiationInfo().filename, $instantiationInfo().line, str.join])
    stderr.write("\nPrinting stacktrace...\n")
    writeStackTrace()  
    quit(1)
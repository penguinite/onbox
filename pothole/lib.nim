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
 
from std/strutils import Whitespace, `%`, toLowerAscii, join
from std/times import now, utc, format
import ../quark/[crypto]

const kdf* {.deprecated: "Use quark/crypto.nim:kdf and not lib.kdf".} = crypto.kdf

# A folder to save debugging data to.
const globalCrashDir* {.strdefine.}: string = "CAR_CRASHED_INTO_POTHOLE!"

# App version
const
  phVersion* {.strdefine.}: string = "0.0.2" ## This constant allows you to customize the potholepkg version that is reported by default using compile-time-directives. Or else just default to the built-in embedded version. To customize the version, just add the following compile-time build option: `-d:phVersion=whatever`
  phMastoCompat* {.strdefine.}: string = "latest"
  phSourceUrl* {.strdefine.}: string = "https://github.com/penguinite/pothole" ## This constant allows you to customize where the source 

const version*{.deprecated: "Use lib.phVersion instead.".}: string = phVersion ## This is basically just phVersion, but it's copied twice for well, code readability purposes.

when not defined(phNoLog):
  template log*(str: varargs[string, `$`]) =
    stdout.write("[$#] ($#:$#): $#\n" % [now().utc.format("yyyy-mm-dd hh:mm:ss"), instantiationInfo().filename, $instantiationInfo().line, str.join])
else:
  template log*(msg: varargs[string, `$`]) = return

template error*(str: varargs[string, `$`]) =
  ## Exits the program, writes a stacktrace and thats it.
  stderr.write("\nPrinting stacktrace...\n")
  writeStackTrace()  
  stderr.write("\n!ERROR! [$#] ($#:$#): $#\n" % [now().utc.format("yyyy-mm-dd hh:mm:ss"), instantiationInfo().filename, $instantiationInfo().line, str.join])
  quit(1)
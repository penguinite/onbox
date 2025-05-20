# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This file is part of Onbox.
# 
# Onbox is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Onbox is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Onbox. If not, see <https://www.gnu.org/licenses/>. 
#
# onbox/shared.nim:
## This module contains procedures, templates, constants and other data
## to be shared across Onbox, or that is used many times across many places.
## 
## Some of the stuff included here is the globalCrashDir constant for post-mortem debugging
## API compatability level constant, source repo URL constant and log + error procedures.

# Originally, the plan was to retire this module ASAP and move the data here elsewhere
# But increasingly, it doesn't look like this module will be retired.
# Instead, we have yet another "shared" module (quark/shared)
# So, TODO: Merge quark/shared and Onbox/lib or get rid of both.

# Useful data
const
  globalCrashDir* {.strdefine.}: string = "ONBOX_SUDDENLY_OFFLINE" ## Which folder to use when storing data for post-mortem debugging in crashes.
  version* {.strdefine.}: string = "0.0.2" ## To customize the version, compile with the option: `-d:version=whatever`
  mastoCompat* {.strdefine.}: string = "wip" ## The level of API compatability, this option doesn't do anything. It's just reported in the API.
  sourceUrl* {.strdefine.}: string = "https://github.com/penguinite/onbox" ## To customize the source URL, compile with the option: `-d:sourceUrl="Link"`

import std/[strutils, tables, times]
  
template log*(str: varargs[string, `$`]) =
  stdout.write("[$#] ($#:$#): $#\n" % [now().utc.format("yyyy-mm-dd hh:mm:ss"), instantiationInfo().filename, $instantiationInfo().line, str.join])

template error*(str: varargs[string, `$`]) =
  ## Exits the program with an error messages and a stacktrace.
  stderr.write("\n!ERROR! [$#] ($#:$#): $#\n" % [now().utc.format("yyyy-mm-dd hh:mm:ss"), instantiationInfo().filename, $instantiationInfo().line, str.join])
  stderr.write("\nPrinting stacktrace...\n")
  writeStackTrace()  
  quit(1)

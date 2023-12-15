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
# ctl/ext.nim:
## Operations related to extensions.
## It does stuff like reveal the embedded metadata and uh... stuff...

# From ctl/ folder in Pothole
import shared

# From elsewhere in Pothole
import ../mrf

# From standard libraries
import std/strutils except isEmptyOrWhitespace
import std/[dynlib, os, tables, posix]

proc processCmd*(cmd: string, data: seq[string], args: Table[string,string]) =
  if args.check("h","help"):
    helpPrompt("ext",cmd)

  case cmd:
  of "view":
    if len(data) == 0:
      echo "Please provide filename for module to inspect."

    for filename in data:
      if isEmptyOrWhitespace(filename):
        continue

      if not fileExists(filename):
        echo "Filename " & filename & " does not exist."
        continue
    
      log "Inspecting file " & filename

      var lib: LibHandle

      if not filename.startsWith('/') or not filename.startsWith("./"):
        lib = loadLib("./" & filename)
      else:
        lib = loadLib(filename)
        
      if lib == nil:
        log "Failed to load library, dlerror output: ", $dlerror()

      echo "potholectl will run a couple of tests, these try to show what features/filters this MRF policy has."
      echo "If there is no output then it means this MRF policy has no features or potholectl couldnt detect them."

      if cast[PostFilterProc](lib.symAddr("filterIncomingPost")) != nil:
        log "This MRF policy filters incoming posts"
      if cast[PostFilterProc](lib.symAddr("filterOutgoingPost")) != nil:
        log "This MRF policy filters outgoing posts"

      if cast[UserFilterProc](lib.symAddr("filterIncomingUser")) != nil:
        log "This MRF policy filters incoming users"
      if cast[UserFilterProc](lib.symAddr("filterOutgoingUser")) != nil:
        log "This MRF policy filters outgoing users"

      if cast[ActivityFilterProc](lib.symAddr("filterIncomingActivity")) != nil:
        log "This MRF policy filters incoming activities"
      if cast[ActivityFilterProc](lib.symAddr("filterOutgoingActivity")) != nil:
        log "This MRF policy filters outgoing activities"
      

  of "check_config":
    return
  of "enable":
    return
  else:
    helpPrompt("mrf")
    

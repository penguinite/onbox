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
# ctl/mrf.nim:
## Operations related to extensions.
## It does stuff like reveal the embedded metadata and uh... stuff...

# From somewhere in Quark
import quark/[strextra]

# From somewhere in Pothole
import pothole/mrf

# From somewhere in the standard library
import std/strutils except isEmptyOrWhitespace, parseBool
import std/[dynlib, os, posix]

proc mrf_view*(filenames: seq[string]): int =
  ## Shows a helpful feature summary for a custom MRF policy.
  ## 
  ## When given a filename, or multiple filenames, it will go through and find the module.
  ## Then it will link it and run a bunch of tests to see what filters it has.
  ## 
  ## If there is no output from this command, then you either gave it a module it couldn't load
  ## or the MRF policy you successfully loaded has no filters.
  ## 
  ## Obviously, don't run this command on anything you didn't compile yourself
  ## Since it's an unsafe command.
  if len(filenames) == 0:
    echo "Please provide modules to inspect."
    quit(1)

  for filename in filenames:
    if isEmptyOrWhitespace(filename):
      continue

    if not fileExists(filename):
      echo "File " & filename & " does not exist."
      continue
  
    echo "Inspecting file " & filename
    var lib: LibHandle
    if not filename.startsWith('/') or not filename.startsWith("./"):
      lib = loadLib("./" & filename)
    else:
      lib = loadLib(filename)
      
    if lib == nil:
      echo "Failed to load library, dlerror output: ", $dlerror()

    if lib.getFilterIncomingPost() != nil:
      echo "This MRF policy filters incoming posts"
    if lib.getFilterOutgoingPost() != nil:
      echo "This MRF policy filters outgoing posts"

    if lib.getFilterIncomingUser() != nil:
      echo "This MRF policy filters incoming users"
    if lib.getFilterOutgoingUser() != nil:
      echo "This MRF policy filters outgoing users"

    if lib.getFilterIncomingActivity() != nil:
      echo "This MRF policy filters incoming activities"
    if lib.getFilterOutgoingActivity() != nil:
      echo "This MRF policy filters outgoing activities"
  return 0

proc mrf_compile*(filenames: seq[string]): int =
  ## Compiles an MRF policy from Nim to a dynamic module
  ## 
  ## When given a filename, or multiple filenames, it will go through and compile each module.
  ## 
  ## Obviously, don't run this command on anything you didn't read the source of
  ## Since compile-time code *can* be dangerous to run
  if len(filenames) == 0:
    echo "Please provide files to compile."
    quit(1)

  for filename in filenames:
    if isEmptyOrWhitespace(filename):
      continue

    if not fileExists(filename):
      echo "File " & filename & " does not exist."
      continue

    let cmd = "nim cpp --app:lib " & filename
    echo "Executing command: " & cmd
    discard execShellCmd(cmd)

  return 0
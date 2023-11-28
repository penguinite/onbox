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
# conf.nim:
## This module wraps configuration file parsers, it also has some essential functions
## Such as getConfigFilename()
## Currently, this module serves as a wrapper over the iniplus config parser.

# From pothole
import lib

# From standard library
import std/[os, tables]
import std/strutils except isEmptyOrWhitespace

# From elsewhere
import iniplus
export iniplus

# Required configuration file options to check for.
# Split by ":" and use the first item as a section and the other as a key
const requiredConfigOptions*: Table[string, seq[string]] = {
  "instance": @["name", "description", "uri"]
}.toTable

proc setupInput*(input: string, check: bool = true): ConfigTable =
  ## This procedure does the same thing as setup() but it accepts the input it gets
  ## in the parameter as the actual config file.
  result = parseString(input)
  if check:
    for section,preKey in requiredConfigOptions.pairs:
      for key in preKey:
        if not result.exists(section, key):
          error "Missing essential key \"", key, "\" in section \"", section, "\""
  return result

proc setup*(filename: string, check: bool = true): ConfigTable =
  return setupInput(open(filename).readAll(), check)

proc getTable*(table: ConfigTable, section, key: string): Table[string, string] =
  let
    arr1 = table.getStringArray(section, key)
    arr2 = table.getStringArray(section, key & "_reasons")
 
  if len(arr1) != len(arr2):
    log "Length of array 1 (Key: \"", key ,"\", Section: \"", section ,"\"): ", len(arr1)
    log "Length of array 2 (Key: \"", key & "_reasons" ,"\", Section: \"", section ,"\"): ", len(arr2)
    error "Lengths do not match, please double check your configuration."
  
  var i = -1
  let arr2Len = high(arr2) # Caching it so we don't call this all the time.
  for key in arr1:
    inc(i)
    if i > arr2Len:
      break
 
    let val = arr2[i]
    result[key] = val
  return result 

proc getConfigFilename*(): string =
  result = "pothole.conf"
  if existsEnv("POTHOLE_CONFIG"):
    result = getEnv("POTHOLE_CONFIG")
  return result

proc isNil*(table: ConfigTable): bool =
  var i = 0;
  for key in table.keys:
    inc(i)

  if i > 0:
    return false
  else:
    return true
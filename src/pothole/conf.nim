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
import std/strutils except isEmptyOrWhitespace, parseBool

# From elsewhere
import iniplus
export iniplus

# Required configuration file options to check for.
# Split by ":" and use the first item as a section and the other as a key
const requiredConfigOptions*: Table[string, seq[string]] = {
  "instance": @["name", "summary", "uri"]
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
  return setupInput(
    readFile(filename),
    check
  )

proc getBoolOrDefault*(config: ConfigTable, section, key: string, default: bool): bool =
  if config.exists(section, key):
    return config.getBool(section, key)
  return default

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
  # We can cheat a bit and just check for the existence of a required key.
  if len(table) == 0:
    return true
  return false

proc getIntOrDefault*(config: ConfigTable, section, key: string, default: int): int =
  if config.exists(section, key):
    return config.getInt(section, key)
  return default

proc getStringArrayOrDefault*(config: ConfigTable, section, key: string, default: seq[string]): seq[string] = 
  if config.exists(section, key):
    return config.getStringArray(section, key)
  return default

proc getEnvOrDefault*(env: string, default: string): string =
  if not existsEnv(env):
    return default
  return getEnv(env)

import waterpark

type
  ConfigPool* = object
    pool: Pool[ConfigTable]

proc borrow*(pool: ConfigPool): ConfigTable {.inline, raises: [], gcsafe.} =
  pool.pool.borrow()

proc recycle*(pool: ConfigPool, conn: ConfigTable) {.inline, raises: [], gcsafe.} =
  pool.pool.recycle(conn)

proc newConfigPool*(size: int, filename: string = getConfigFilename()): ConfigPool =
  result.pool = newPool[ConfigTable]()
  try:
    for _ in 0 ..< size:
      result.pool.recycle(setup(filename))
  except CatchableError as err:
    error "Couldn't initialize config pool: ", err.msg

template withConnection*(pool: ConfigPool, config, body) =
  block:
    let config = pool.borrow()
    try:
      body
    finally:
      pool.recycle(config)
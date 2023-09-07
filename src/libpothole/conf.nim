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
## This modules provides access to a custom written configuration file parser.
## And it also provides access to several helper functions for retrieving and parsing
## data from a shared config table.

import std/[tables, os]
from std/strutils import split, startsWith, endsWith, splitLines, parseBool, parseInt
import lib

# Required configuration file options to check for.
# Split by ":" and use the first item as a section and the other as a key
const requiredConfigOptions*: seq[string] = @[
  "instance:name",
  "instance:description",
  "instance:uri"
]

func split*(obj: string): seq[string] =
  ## A function to convert a string to a sequence of strings.
  var 
    parsingFlag: bool = false
    val: string = ""
  
  for ch in obj:
    if ch == '"':
      if parsingFlag:
        parsingFlag = false
        result.add(val)
        val = ""
      else:
        parsingFlag = true
      continue

    if parsingFlag:
      val.add(ch)
  
  return result

func load*(input: string): Table[string, string] =
  ## This function parses the configuration file and returns a config table.
  var
    parsingFlag = false # A flag that indicates whether or not we are parsing something right now
    parsingX = 0 # A number indicating what thing we are parsing.
    section = "" # A string containing the section that we are parsing
    key = "" # a string containing the key being parsed
    val = "" # A string containing a value being parsed

  #[
    ParsingX follows this format:
      0 means we are not parsing anything
      1 means we are parsing a section
      2 means we are parsing a key
      3 means we are parsing a value
      4 means we are parsing an array
  ]#

  for line in input.splitLines:
    if line.startsWith("#") or line.isEmptyOrWhitespace():
      continue # Line is either a comment or empty

    for ch in line:
      if ch == '[' and parsingX == 0:
        parsingX = 1
        section = "" 
        continue

      if parsingX == 1:
        if ch == ']':
          parsingX = 0
        else:
          section.add(ch)
        continue

      if parsingX > 2: # Parsing val
        if ch == '"':
          if parsingFlag:
            parsingFlag = false
          else:
            parsingFlag = true

        if ch == '[' and not parsingFlag:
          parsingX = 4
        elif ch == ']' and parsingX == 4 and not parsingFlag:
          parsingX = 3
        val.add(ch)
        continue
      else:
        if ch == '=':
          parsingX = 3
        else:
          key.add(ch)

    if not isEmptyOrWhitespace(section) and not isEmptyOrWhitespace(key) and not isEmptyOrWhitespace(val) and parsingX != 4:
      if val.startsWith('"'):
        val = val.substr(1)
      if val.endsWith('"'):
        val = val.substr(0,high(val) - 1)
      result[section & ":" & key] = val
      key = ""
      val = ""
      parsingX = 0

proc setupInput*(input: string): Table[string, string] =
  ## This procedure does the same thing as setup() but it accepts the input it gets
  ## in the parameter as the actual config file. This is basically a wrapper over load()
  result = load(input) # Open the config file
  # Now... We have to check if our required configuration
  # options are actually there
  for x in requiredConfigOptions:
    if not result.hasKey(x):
      var list = x.split(":")
      error("Missing key \"" & list[1] & "\" in section \"" & list[0] & "\"", "conf.setupInput")
  return result

proc setup*(filename:string): Table[string,string] =
  ## A procedure that readies the config table to be read.
  ## The actual parsing is done in the load() function.
  ## Array splitting is done in split()
  if not fileExists(filename):
    error("File \"" & filename & "\" does not exist.", "conf.setup")
  
  return setupInput(open(filename).readAll()) 

proc exists*(table: Table[string, string], section, key: string): bool =
  if table.hasKey(section & ":" & key):
    return true
  return false # Return nothing

## Functions for fetching specific datatypes
func getString*(table: Table[string, string], section, key: string): string =
  return table[section & ":" & key]

func getStringOrDefault*(table: Table[string, string], section, key, default: string): string =
  if table.hasKey(section & ":" & key):
    return table[section & ":" & key]
  else:
    return default

func getInt*(table: Table[string, string], section, key: string): int =
  return parseInt(table[section & ":" & key])

func getBool*(table: Table[string, string], section, key: string): bool =
  if not table.hasKey(section & ":" & key):
    return false
  return parseBool(table[section & ":" & key])

func getArray*(table: Table[string, string], section, key: string): seq[string] =
  return split(table[section & ":" & key])

proc getConfigFilename*(): string =
  result = "pothole.conf"
  if existsEnv("POTHOLE_CONFIG"):
    result = getEnv("POTHOLE_CONFIG")
  return result
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
import std/strutils except isEmptyOrWhitespace
import lib

export tables

# Required configuration file options to check for.
# Split by ":" and use the first item as a section and the other as a key
const requiredConfigOptions*: seq[string] = @[
  "instance:name",
  "instance:description",
  "instance:uri"
]

const specialCharset: set[char] = {' ', '\t', '\v', '\r', '\l', '\f', '"'}

# These types are used when parsing the config file.
# None means... None obviously.
# Section is the [EXAMPLE] part.
# Value is the stuff following the equal sign. Confusingly, the "Key" is parsed in the "None" stage.
# Multi is any multi-line object such as an array or table.
type
  ParsingMode = enum
    None, Section, Value, Multi

func split*(obj: string): seq[string] =
  ## A function to convert a string to a sequence of strings.
  ## Used for single string arrays
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

func quickSplit*(str: string, key: char): seq[string] =
  var container = ""
  for ch in str:
    if ch == key:
      result.add(container)
      container = ""
      continue
    container.add(ch)
  result.add(container)
  return result

func convertRawTable*(str: string): Table[string, string] =
  var
    key = ""
    val = ""
    backslash = false
    count = 0

  for ch in str:
    if ch == '\\':
      backslash = true
      continue

    if ch == '"' and not backslash:
      inc(count)
      continue

    if backslash: backslash = false

    if count mod 2 != 0:
      if count > 2:
        val.add(ch)
      else:
        key.add(ch)
      continue

    if count >= 4:
      count = 0
      key = key.cleanString(specialCharset)
      val = val.cleanString(specialCharset)
      result[key] = val
      key = ""
      val = ""

  debugEcho(count)
  debugEcho(result)

func load*(input: string): Table[string,string] = 
  var
    mode: ParsingMode = None
    backslash = false
    section = ""
    key = ""
    value = ""  

  for line in input.splitLines:
    if mode != Multi:
      # If we aren't parsing a Multiline thing then reset the mode
      mode = None

      # Clear "key" if it has something in it.
      # The key should not be cleared if we are parsing a Table or Array
      if len(key) > 0: key = "" 

    # Skip line if its mostly empty or a comment.
    if line.isEmptyOrWhitespace() or line.startsWith("#"): continue

    for ch in line:
      case mode:
      of None:
        # Skip line if its a comment
        if ch == '#': continue

        # Start parsing section
        if ch == '[':
          mode = Section
          section = "" 
          continue
        
        # Start parsing value
        if ch == '=':
          mode = Value
          value = ""
          continue

        # If neither of those two has matched then we just add it as key.
        key.add(ch)
      of Section:
        if ch == ']':
          mode = None # Reset mode back if the section has ended
        else:
          section.add(ch)
      of Value:
        if value == "" and ch == '{': 
          mode = Multi
          continue

        if ch == '\\':
          continue

        value.add(ch)
      of Multi:
        if backslash and ch == '}':
          value.add("\\}")
          continue
        else:
          if ch == '\\':
            backslash = true
            continue
          if ch == '}':
            mode = None
            continue
          value.add(ch)
        
    # If we aren't parsing a Multiline thing then reset the mode
    # We want to actually preserve the key this time.  
    if mode != Multi: mode = None

    #debugEcho "Section: ", section
    #debugEcho "Key: ", key
    #debugEcho "Value: ", value
    #debugEcho "Mode: ", mode

    if mode == None and len(value) > 0 and len(key) > 0:
      # Trim quotation mark at beginning if it exists
      if value[0] == '"': value = value[1..^1]
      # Trim quotation mark at end if it exists
      if value.endsWith('"'): value = value[0..^2]


      key = key.cleanString(specialCharset)
      value = value.cleanString(specialCharset)

      result[section & ':' & key] = value
      # Reset key and value.
      # Section will be naturally reset
      key = ""
      value = ""
      continue

  return result

proc setupInput*(input: string, check: bool = true): Table[string, string] =
  ## This procedure does the same thing as setup() but it accepts the input it gets
  ## in the parameter as the actual config file. This is basically a wrapper over load()
  result = load(input) # Open the config file
  # Now... We have to check if our required configuration
  # options are actually there
  if check:
    for x in requiredConfigOptions:
      if not result.hasKey(x):
        var list = x.quickSplit(':')
        error "Config file is missing essential key \"$#\" in section \"$#\"" % [list[1], list[0]]
  return result

proc setup*(filename:string, check: bool = true): Table[string,string] =
  ## A procedure that readies the config table to be read.
  ## The actual parsing is done in the load() function.
  ## Array splitting is done in split()
  if not fileExists(filename):
    error "File \"$#\" does not exist." % [filename]
  
  return setupInput(open(filename).readAll(), check) 

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

func getTable*(table: Table[string, string], section, key: string): Table[string, string] =
  return convertRawTable(table.getString(section, key))

proc getMRFConfig*(table: Table[string, string], keyword:string = ""): Table[string,string] =
  ## This proc takes a regular config table and then returns a table containing only the MRF policy requested.
  ## This is not as simple as just getTable("mrf.KEYWORD")
  ## 
  ## We do not want MRF policies outside of Pothole to have access to database settings for security and performance reasons.
  ## Even if they could easily get the file themselves. Such as by importing this file and running setup(getConfigFilename())
  ## And also! The config file could point to a separate config file as the MRF policy configuration.
  ## So this proc just handles everything for us, so we dont worry about it.
  var mrfTable: Table[string, string] = initTable[string,string]()

  if table.exists("mrf","config") and not isEmptyOrWhitespace(table.getString("mrf","config")) and keyword != "":
    mrfTable = setup(table.getString("mrf","config"), false)
  else:
    mrfTable = table

  var head = "mrf:"
  if keyword != "":
    head = "mrf." & keyword & ":"

  for key in mrfTable.keys:
    if key.startsWith(head):
      var tail = key.quickSplit(':')[1]
      result[head & tail] = mrfTable[key]
  
  return result
      

proc getConfigFilename*(): string =
  result = "pothole.conf"
  if existsEnv("POTHOLE_CONFIG"):
    result = getEnv("POTHOLE_CONFIG")
  return result

proc isNil*(table: Table[string, string]): bool =
  var i = 0;
  for key in table.keys:
    inc(i)

  if i > 0:
    return false
  else:
    return true
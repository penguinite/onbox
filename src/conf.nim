# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later.
# conf.nim:
## This modules provides access to a custom written configuration file parser.
## And it also provides access to several helper functions for retrieving and parsing
## data from a shared config table.

import std/[tables, os]
import std/strutils except isEmptyOrWhitespace
import lib

var config: Table[string, string] = initTable[string, string]()

func split*(obj: string): seq[string] =
  ## A function to convert a string to a
  ## sequence of strings.
  var parsingFlag: bool = false # A flag indicating whether or not we are parsing a value right now.
  var val = "" # A string to store the value being parsed.
  for ch in obj:
    if ch == '\"':
      if parsingFlag:
        parsingFlag = false
        result.add(val)
        val = ""
      else:
        parsingFlag = true
      continue
    
    if parsingFlag:
      val.add(ch)

func load*(input: string): Table[string, string] =
  ## This module parses the configuration file and returns a config table.
  result = initTable[string, string]()

  var
    sectionFlag = false # A flag that indicates whether or not we are parsing a section.
    parsingFlag = false # A flag that indicates whether or not we are parsing a key:value pair
    arrayFlag = false # A flag indicating whether or not we are parsing an array.
    prevArrayFlag = false # A flag that stores the previous state of array
    section = "" # A string containing the section that we are parsing
    key = "" # a string containing the key being parsed
    val = "" # A string containing a value being parsed


  # I actually have no idea how this works.
  # It works but like I can't even explain it...
  # Just don't touch it... Or you'll have to re-write it...
  for line in input.splitLines:
    if line.startsWith("#"):
      continue

    for ch in line:
      if ch == '[':
        if not parsingFlag:
          section = ""
          sectionFlag = true  
        else:
          arrayFlag = true
          val.add(ch)
        continue

      if ch == ']':
        if arrayFlag:
          arrayFlag = false
          prevArrayFlag = true
          val.add(ch)
          continue

        if sectionFlag:
          sectionFlag = false
          continue

      if sectionFlag:
        section.add(ch)
        continue

      if ch == '=':
        if parsingFlag:
          val.add(ch)
        else:
          parsingFlag = true
        continue

      if not parsingFlag:
        key.add(ch)
      else:
        val.add(ch)

    if not arrayFlag:
      if len(key) > 0:
        if val.startsWith('\"'):
          val = val[1 .. len(val) - 1]
        if val.endsWith('\"'):
          val = val[0 .. len(val) - 2]
        result[section & ":" & key] = val
        key = ""
        val = ""
        parsingFlag = false

    if not arrayFlag and prevArrayFlag:
      if len(key) > 0:
        result[section & ":" & key] = val
        key = ""
        val = ""
        parsingFlag = false
        prevArrayFlag = false

proc setup*(filename: string): bool =
  ## A procedure that readies the config table to be read.
  ## The actual parsing is done in the load() function.
  ## Array splitting is done in split()
  try:
    if not fileExists(filename):
      error "File " & filename & " does not exist.", "conf.setup"
    var file = open(filename)
    config = load(readAll(file))
    file.close() # Close the file at the end
    # Now... We have to check if our required configuration
    # options are actually there
    for x in lib.requiredConfigOptions:
      if config.hasKey(x):
        continue
      else:
        var list = x.split(":")
        debug("Missing key " & list[1] & " in section " & list[0], "main.startup")
        return false
    return true
  except:
    return false

proc get*(section, key: string, table: Table[string, string] = config): string =
  return table[section & ":" & key]

proc exists*(section, key: string, table: Table[string, string] = config): bool =
  if table.hasKey(section & ":" & key):
    return true
  else:
    return false
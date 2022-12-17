# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.
# conf.nim	;;	Various functions for retrieving configuration data

import std/tables
import std/strutils

# This table will be accessible to all who need it.
# Unfortunately, due to Nim's lack of type inference (It does have it but it is not usable here)
# We will need a bunch of wrapper functions to convert and parse strings.
var configTable = initTable[string,string]()

# Parse through the config file
# and create an optimized "Table" (What you would call Dictionary in Python)
# This is most likely faster than storing the config file directly
# in memory
# Our config format only has one key and one value corressponding to that key
# Dictionaries have the exact same format which means we can
# simply provide functions for converting specific data types into different things.
#var config
proc setup*(configfile: string):Table[string,auto] {.discardable.} =
    return configTable

# A bunch of functions I have declared now, instead of later.
# These are all of the data types in the config language

# This function checks if a specific key exists in the config file
proc exists(key: string): bool =
    return true

proc getString(key: string): string =
    return ""

proc getInt(key: string): int =
    return 1

proc getArray(key:string): Table[string,string] =
    var uselessTrash = initTable[string,string]()
    return uselessTrash
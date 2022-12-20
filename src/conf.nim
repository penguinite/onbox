# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.
# conf.nim	;;	Various functions for retrieving configuration data

import std/tables
import std/strutils
import lib

# This table will be accessible to all who need it.
# Unfortunately, due to Nim's lack of type inference (It does have it but it is not usable here)
# We will need a bunch of wrapper functions to convert and parse strings.
#var configTable = initTable[string,string]()
var configTable* = initTable[string,string]()

# Parse through the config file
# and create an optimized "Table" (What you would call Dictionary in Python)
# This is most likely faster than storing the config file directly
# in memory
# Our config format only has one key and one value corressponding to that key
# Dictionaries have the exact same format which means we can
# simply provide functions for converting specific data types into different things.
#var config
proc setup*(configfile: string):Table[string,string] {.discardable.} =

    return configTable

# A bunch of functions I have declared now, instead of later.
# These are all of the data types in the config language

# This function checks if a specific key exists in the config file
proc exists*(key: string): bool =
    return true

# This function simply gets a key and
# returns it as a string.
# This is a very basic function and so it needs to be
# wrapped over.
proc get*(key: string): string =
    return ""

# These functions simply wrap over get() and exists()
# to provide a sane, usable interface and to convert the
# supposed data types to what they say they are.
proc getString*(key: string): string =
    if exists(key) == false:
        lib.err("Key" & key & "could not be found","conf.getString()")
    return get(key)

proc getInt*(key: string): int =
    if exists(key) == false:
        lib.err("Key" & key & "could not be found","conf.getInt()")
    return parseInt(get(key))
    
proc getArray*(key:string): seq[string] =
    if exists(key) == false:
        lib.err("Key" & key & "could not be found","conf.getBool()")
    return @[""]

proc getBool*(key: string): bool =
    if exists(key) == false:
        lib.err("Key" & key & "could not be found","conf.getBool()")
    var val: string = get(key)
    # So first we make it all lowercase
    val = toLower(val)
    if startsWith(val,"true"):
        return true
    if startsWith(val,"yes"):
        return true
    if startsWith(val,"0"):
        return true
    return false
# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.
# conf.nim	;;	Various functions for retrieving configuration data

import std/tables # For handling tables.
import std/strutils # For string handling.
import os # For some filesystem operations.
import lib # Shared data, funcs etc.

# This table will be accessible to all who need it.
# Unfortunately, due to Nim's lack of type inference (It does have it but it is not usable here)
# We will need a bunch of wrapper functions to convert and parse strings.
#var configTable = initTable[string,string]()
var 
    configTable* = initTable[string,string]()
    configTableA* = initTable[string,seq[string]]()

# A set of required options
# This will be check for in setup()
# Any missing options will immediately
# error out.
var requiredOptions: seq[string] = @[
    "dbtype"
]


# This cleans up a string, for single-values.
proc clean*(str: string, quoteRemove: bool = true, leading: bool = true, trailing: bool = true, optend: bool = true): string =
    var endnum: int = len(str) - 1
    var startnum: int = 0
    const chars: set[char] = {' ', '\t', '\v', '\r', '\l', '\f'}
    
    # Remove whitespace characters
    # strutils/strbasics strip() func does not work for me.
    # So this is what I had to do.
    if leading:
        while str[startnum] in chars: 
            inc(startnum)
    if trailing:
        while endnum >= 0 and str[endnum] in chars: 
            dec(endnum)

    if quoteRemove:
        if str[endnum] == '"':
            dec(endnum)
        if str[startnum] == '"':
            inc(startnum)

    # Strip again...
    if optend:
        if leading:
            while str[startnum] in chars: 
                inc(startnum)
        if trailing:
            while endnum >= 0 and str[endnum] in chars: 
                dec(endnum)

    return str[startnum..endnum]

# We need to process this char by char.
proc parseArray(str:string): seq[string] = 
    var arr: seq[string] = @[];
    var val: string;
    var flags: seq[int] = @[
        0, # Are we in the middle of parsing something? flag.
        0, # Was there a backslash before? flag
    ]
    for c in str:
        if c == '"':
            # Check if we are processing something, if so then 
            # end it unless there has been a backslash previously
            if flags[0] == 1:
                # No backslash
                if flags[1] == 0:
                    flags[0] = 0 # End processing
                    arr.add(val)
                    val = ""
                else:
                    flags[1] = 0
                    # Add a quote backslash
                    val.add('"')
                continue
            else:
                # Start processing
                flags[0] = 1
                continue

        # Detect backslash character
        if c == '\\':
            flags[1] = 1 # Set backslash character
            continue
        
        # Add it to the list
        if flags[0] == 1:
            val.add(c)

    return arr

# Parse through the config file
# and create an optimized "Table" (What you would call Dictionary in Python)
# This is most likely faster than storing the config file directly
# in memory
# Our config format only has one key and one value corressponding to that key
# Dictionaries have the exact same format which means we can
# simply provide functions for converting specific data types into different things.
proc setup*(configfile: string): bool {.discardable.} =
    if os.fileExists(configfile) == false:
        lib.err("File " & configfile & " could not be accessed!","conf.setup.fileExists")

    # A bunch of flags. We want Nim to free these ASAP
    # So let's not include them in the main thread.
    var flags: seq[int] = @[
        0, # Are we processing an array? flag
        0, # How many lines are in a multiline array? flag
        0, # Have we previously processed an array? flag
    ];
    var countl: int = 0; # A int to store the count of lines
    var val: string = ""; # A string to store keys
    var key: string = ""; # A string to process single-value options

    var f: File = open(configfile, fmRead)
    var lines: seq[string] = @[]; # A function to store lines without comments. We need this for multi-line arrays.

    # Get only the useful lines.
    for line in f.lines:
        if line.startsWith("#"):
            continue   
        lines.add(line)

    # Close the file as we don't need it anymore
    close(f)

    # Here comes the complicated bit, brace yourselves.
    for line in lines:
        inc(countl)

        if contains(line,"=") and flags[0] == 0:
            # Split on the equal sign, use the first part
            # as the key and the second part as a value.
            key = split(line,"=")[0] # Get key
            val = line[len(key) + 1..len(line) - 1] # Get val by removing length of key
            
            # Clean up the strings
            # To make sure no nasty whitespace
            # ruins our parsing.
            key = clean(toLower(key))
            val = clean(val)

            # Now we want to see if we have processed an array
            # Or a regular key item.
            if val.startsWith("["):
                # Array detected
                flags[0] = 1

        # Let's try to process multi-line stuff
        # With line-by-line code.
        if flags[0] == 1:
            if contains(line, "]"):
                # The array ends at this line
                # So let's try to get all lines together.
                if flags[1] <= 0:
                    # The entire array in on one line.
                    key = toLower(clean(key))
                    flags[2] = 1 # Tell the program to add an array to the config table
                    flags[0] = 0 # Set the array flag to 0
                    flags[1] = 0
                else:
                    inc(flags[1])
                    # The array is multiline, let's combine
                    # it to one big string that we can
                    # pass to parseArray()
                    key = split(lines[countl - flags[1]],"=")[0]

                    val = ""
                    for i in countl - flags[1] .. countl - 1:
                        val.add(clean(lines[i],false))

                    key = clean(toLower(key))
                    if val.contains("="):
                        val = val[len(key) + 1..len(val) - 1]
                    
                    # Reset all the flags
                    flags[0] = 0
                    flags[1] = 0
                    flags[2] = 1
                    
            else:
                # Increase count by one
                inc(flags[1])
                continue

        # At this point, we have probably done all we can.
        # Let's finally insert the key-value pair.
        # Debug note: This is SingleHit
        if flags[0] == 0 and flags[2] == 0:
            if isEmptyOrWhitespace(key) or isEmptyOrWhitespace(val):
                continue # Key/Val is empty so we skip the iteration

            lib.debug("Single! Key: " & $key & ", Val: " & $val & ", Line: " & $line,"conf.setup.SingleHit")
            configTable[key] = val;
            
            # Reset the vars
            key = ""
            val = ""
            
        
        # We have just finished processing an array
        # So let's add it into the table.
        # Debug note: This is ArrayHit
        if flags[2] == 1:
            # Process the array right before putting it in
            flags[2] = 0
            
            if isEmptyOrWhitespace(key) or isEmptyOrWhitespace(val):
                continue # Key/Val is empty so we skip the iteration
            
            lib.debug("Array! Key: " & $key & ", Val: " & $val & ", Line: " & $line,"conf.setup.ArrayHit")
            configTableA[key] = parseArray(val);

            # Reset the vars
            val = ""
            key = ""

    # Now let's check for any missing options
    for x in requiredOptions:
        if configTable.hasKey(x) == true:
           continue
        if configTableA.hasKey(x) == true:
            continue
        lib.err("Missing required option " & x,"conf.setup.requiredOptionsCheck")

    return true

# A bunch of functions I have declared now, instead of later.
# These are all of the data types in the config language

# This function checks if a specific key exists in the config file
proc exists*(key: string): bool =
    if configTable.hasKey(key):
        return true
    if configTableA.hasKey(key):
        return true
    return false

# This function simply gets a key and
# returns it as a string.
# This is a very basic function and so it needs to be
# wrapped over.
proc get*(key: string): string =
    return configTable[key]

# We can only store strings in the table so some special
# handling is needed here. 
# We need a neutral character when parsing the config file
# Note for later:
    # configTable[listKey] = 
proc getmul*(key: string): seq[string] =
    return configTableA[key]

# These functions simply wrap over get() and exists()
# to provide a sane, usable interface and to convert the
# supposed data types to what they say they are.
proc getString*(key: string): string =
    if exists(key) == false:
        lib.err("Key " & key & " could not be found","conf.getString")
    return configTable[key]

proc getInt*(key: string): int =
    if exists(key) == false:
        lib.err("Key " & key & " could not be found","conf.getInt")
    return parseInt(configTable[key])

proc getBool*(key: string): bool =
    if exists(key) == false:
        lib.err("Key " & key & " could not be found","conf.getBool")
    var val: string = configTable[key]
    # So first we make it all lowercase
    val = clean(toLower(val))
    if startsWith(val,"true"):
        return true
    elif startsWith(val,"yes"):
        return true
    else:
        return false

proc getArray*(key:string): seq[string] =
    if exists(key) == false:
        lib.err("Key " & key & " could not be found","conf.getArray")
    return configTableA[key]
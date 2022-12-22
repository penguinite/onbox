# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.
# lib.nim ;; Shared data values across the app

import std/db_sqlite

var doesDbExist*: bool = false;
var db*: DbConn = nil;
var lastwarn*: string = ""; # A variable to store the last-recorded warning.
var ver*:string = "0.0.1"

# Debug level
# 1: Very basic info
# 2: 1 + output from db.setup()
# 3: 2 + conf.setup()
# 4: All output...
var debugMode*:int = 1;
var debugBuffer*:seq[string] = @[];

# A convenient exit function
# This also closes the database
# so no corruption occurs.
proc exit*(code: int = 0): bool {.discardable.} =
    # Close database before quitting.
    if doesDbExist == true:
        db.close()
    quit(code)

# Functions to print to stderr.
# This is mostly for wrapping.
# An error immediately crashes the
# program
proc err*(cause:string,place:string): bool {.discardable.} =
    var tobePrinted = "Error (" & place & "): " & cause # For some strange reason, we need to do it like this
    stderr.writeLine(tobePrinted)
    stderr.writeLine("What follows is our best attempt at making sense of this mess")
    if len(lastwarn) > 0:
        stderr.writeLine("Last warning: ", lastwarn)
    stderr.writeLine("Printing debug buffer:")
    for x in debugBuffer:
        stderr.writeLine(x)
    exit(1)

# A warning is something that isn't as
# urgent.
proc warn*(cause: string, place: string): bool {.discardable.} =
    lastwarn = "Warning (" & place & "): " & cause # For some strange reason, we need to do it like this
    stderr.writeLine(lastwarn)
    return true

# Print to the debugBuffer and maybe stderr
proc debug*(cause: string, place: string, level:int = 1): bool {.discardable.} =
    var tobePrinted = "(" & place & "): " & cause # For some strange reason, we need to do it like this
    if level <= debugMode:
        stderr.writeLine(tobePrinted)
    debugBuffer.add(tobePrinted)
    return true


## User class
# makes it easy to process users.
type User* = object
    id*: string
    name*: string
    email*: string
    handle*: string
    password*: string
    bio*: string
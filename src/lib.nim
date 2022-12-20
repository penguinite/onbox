# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.
# lib.nim ;; Shared data values across the app

# Functions to print to stderr.
# This is mostly for wrapping.

# A warning is something that isn't as
# urgent, but an error is something that the
# program immediately exits out of.
var lastwarn*: string = "";
var debug*:string = "";

proc err*(cause:string,place:string): bool {.discardable.} =
    var tobePrinted = "Error (" & place & "): " & cause # For some strange reason, we need to do it like this
    stderr.writeLine(tobePrinted)
    stderr.writeLine("What follows is our best attempt at making sense of this mess")
    stderr.writeLine(lastwarn)
    stderr.write(debug)
    quit(1)

proc warn*(cause: string, place: string): bool {.discardable.} =
    lastwarn = "Warning (" & place & "): " & cause # For some strange reason, we need to do it like this
    stderr.writeLine(lastwarn)
    return true

# A function to set lib.debug
# This probably isn't needed.
proc setdebug*(cause:string,place:string): bool {.discardable.} = 
    lib.debug = "(" & place & "): " & cause
    return true    

# I wrote a lot of Python the past few weeks
# and I keep confusing these. So I wrote
# some aliases so the code I wrote does
# at least compile no matter if it has
# True instead of true or None instead of nil
#const True = true
#const False = false
#const NULL = nil
#const None = nil
#const null = nil
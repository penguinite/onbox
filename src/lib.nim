# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.
# lib.nim ;; Shared data values across the app

import os

var lastwarn*: string = ""; # A variable to store the last-recorded warning.
var ver*:string = "0.0.1"
# If debugMode is set to true then
# any and all calls to debug()
# will be printed to stderr.
# By default, debugBuffer is only
# printed on errors...
var debugMode*:bool = false;

if existsEnv("POTHOLE_DEBUG"):
    debugMode = true;

var debugBuffer*:seq[string] = @[];

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
    quit(1)

# A warning is something that isn't as
# urgent.
proc warn*(cause: string, place: string): bool {.discardable.} =
    lastwarn = "Warning (" & place & "): " & cause # For some strange reason, we need to do it like this
    stderr.writeLine(lastwarn)
    return true

# Print to the debugBuffer and maybe stderr
proc debug*(cause: string, place: string): bool {.discardable.} =
    var tobePrinted = "(" & place & "): " & cause # For some strange reason, we need to do it like this
    if debugMode == true:
        stderr.writeLine(tobePrinted)
    debugBuffer.add(tobePrinted)
    return true

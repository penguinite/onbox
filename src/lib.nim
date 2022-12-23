# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.
# lib.nim ;; Shared data and procedures across the app

import std/oids

var lastwarn*: string = ""; # A variable to store the last-recorded warning.
var ver*:string = "0.0.1"

# Debug level
# 1: Very basic info
# 2: 1 + output from db.setup()
# 3: 2 + conf.setup()
# 4: All output...
var debugMode*:int = 1;
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

# Custom implementation of isEmptyOrWhitespace
proc isEmptyOrWhitespace(str: string): bool =
    if len(str) <= 0:
        return true

    const chars: set[char] = {' ', '\t', '\v', '\r', '\l', '\f', '\e', ' '}
    for x in str:
        if x notin chars:
            return false
        return true

    return false

# Returns a validated User object
proc fixUser*(user: User): User =
    var newuser: User;
    # These are the things that we *cannot* fix. No matter what.
    if isEmptyOrWhitespace(user.email) or isEmptyOrWhitespace(user.name) or isEmptyOrWhitespace(user.password):
        echo("User: " & $user,"lib.fixUser")
        echo("Missing critical field","lib.fixUser")
        quit(1)
        
    # Add old values
    newuser.name = user.name
    newuser.password = user.password
    newuser.email = user.email

    if isEmptyOrWhitespace(user.id):
        newuser.id = $genOid()
    if isEmptyOrWhitespace(user.handle):
        newuser.handle = user.name
    if isEmptyOrWhitespace(user.bio):
        newuser.bio = "Hello! I'm " & newuser.handle

    return newuser
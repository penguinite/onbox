# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.
# lib.nim ;; Shared data values across the app

var tobePrinted: string;

proc err*(cause:string,place:string): bool {.discardable.} =
    tobePrinted = "Error (" & place & "): " & cause 
    stderr.writeLine(tobePrinted)
    return true

proc warn*(cause: string, place: string): bool {.discardable.} =
    tobePrinted = "Warning (" & place & "): " & cause 
    stderr.writeLine(tobePrinted)
    return true

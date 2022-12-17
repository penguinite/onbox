# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.
# env.nim	;;	For fetching data from the environment

import std/parseopt
import std/strutils
import os

proc getLongOption*(option: string): string =
    var p = initOptParser(commandLineParams().join(" "))
    while true:
        p.next()
        case p.kind
            of cmdEnd: break
            of cmdArgument, cmdShortOption: continue
            of cmdLongOption:
                if p.key == option:
                    return p.val

proc existsLongOption*(option: string): bool =
    var p = initOptParser(commandLineParams().join(" "))
    while true:
        p.next()
        case p.kind 
            of cmdEnd: break
            of cmdArgument, cmdShortOption: continue
            of cmdLongOption:
                if p.key == option:
                    return true;
    return false;
                

proc fetchConfig*(): string =
    var x:string = "pothole.conf" # Temporary variable to protect configfile var
    if existsEnv("POTHOLE_CONFIG"):
        x = getEnv("POTHOLE_CONFGI")

    if existsLongOption("config"):
        x = getLongOption("config")

    return x
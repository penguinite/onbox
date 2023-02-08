# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later.

from std/parsecfg import getSectionValue, Config

# We could put this in lib.nim
# But then we would be making lib.nim too big.
# The whole purpose of this file is to unify config handling among all threads.
# By creating a global inaccessible variable with global GC-safe procedures.

var config: Config;

proc get*(section: string, key: string, default = ""): string =
  {.gcsafe.}:
    return config.getSectionValue(section,key,default)

proc exists*(section: string, key: string): bool =
  {.gcsafe.}:
    if config.getSectionValue(section,key,"__NO_VALYE!") == "__NO_VALYE!":
      return false
    else:
      return true

proc setup*(configTable: Config): bool =
  try:
    {.gcsafe.}:
      config = configTable
    return true
  except:
    return false # ?
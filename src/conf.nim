# Shared functions for handling the configuration file.

import std/parsecfg

var config: Config;

proc get*(section: string, key: string): string =
  {.gcsafe.}:
    return config.getSectionValue(section,key)

proc exists*(section: string, key: string): bool =
  try:
    {.gcsafe.}:
      discard config.getSectionValue(section,key)
    return true
  except:
    return false

proc setup*(newcnf: Config): bool =
  try:
    {.gcsafe.}:
      config = newcnf
    return true
  except:
    return false
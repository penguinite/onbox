# Copyright © Louie Quartz 2022-2023
# Licensed under AGPL Version 3 or later

# From pothole
from crypto import randomString

# From stdlib
from std/parsecfg import getSectionValue, Config

let weirdDefault: string = "PotholeCM:" & randomString(72) & $int.high

## Shared functions for handling the configuration file.
## in the past, Pothole used a custom parser and this
## module provided functions for parsing that custom
## format and that worked fine but parsecfg is very fast 
## too and produces even cleaner configuration file, so 
## I started using it.
## 
## Nowadays the purpose of the conf module is to provide 
## a "shared" configuration table across the entire app
## So, the db module, for example, can import conf and
## get access to the entire configuration file.
## I think that's the best approach.
## 
## The config file is initialized at startup in pothole.nim

var config: Config;

proc get*(section: string, key: string, default = ""): string =
  ## Retrieves a key from a section from the config file
  ## and allows the developer to set a default value
  ## if it does not exist
  ## Please use exists() before using this.

  {.gcsafe.}:
    return config.getSectionValue(section,key,default)

proc exists*(section: string, key: string): bool =
  ## Checks if a key in a section exists.
  ## std/parsecfg does not include a procedure to see
  ## if a key exists, not even close.
  ## So what I do is I create a very long and unpredictable
  ## string, basically something that no practical config file
  ## would actually collide with, and I check using getSectionValue
  ## which conveniently allows us to specify a default value, should
  ## a key not exist.
  # We have to specify an outrageous default value
  # Something only we can detect.
  {.gcsafe.}:
    if config.getSectionValue(section,key,weirdDefault) == weirdDefault:
      return false
    else:
      return true

proc setup*(configTable: Config): bool =
  ## Simply sets conf.config to configTable
  try:
    {.gcsafe.}:
      config = configTable
    return true
  except:
    return false # ?
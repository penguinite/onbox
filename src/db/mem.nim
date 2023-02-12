# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later.
#
# db/mem.nim:
## A database backend that uses the host's memory
## This is not recommended for production builds.
## Please do not use this

import ../lib

proc init*(): bool =
  ## Do any initialization work.
  return true

proc addUser*(user: User): User = 
  ## Add a user to the database
  return user
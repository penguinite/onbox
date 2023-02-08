# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later.
#
# skeleton.nim:
## A template for any future database backends.
## Try to keep your database engine as close to this as possible.

import ../lib

proc init*(): bool =
  ## Do any initialization work.
  return true

proc addUser*(user: User): User = 
  ## Add a user to the database
  return user
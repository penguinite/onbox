# Copyright © Leo Gavilieau 2022-2023
# Licensed under the AGPL version 3 or later.
#
# db.nim: 
## Contains functions for inserting, updating and deleting data depending on which engine.
## This is mostly a compile-time wrapper to whatever database backend you use.
## Supported backends include: sqlite and postgres
## To use sqlite, simply supply "-d:useSqlite" to the nimble build command
## To use postgres, simply supply "-d:usePostgres" to the nimble build command.
#

# Note: This code is quite ugly

# Use sqlite in debug target or when user explicitly chooses it.
when defined(useSqlite):
  import db/sqlite

when defined(usePostgres):
  import db/postgres # TODO: Implement the postgres database engine

proc init*(): bool =
  ## Initializes a database using values from the config file
  when defined(usePostgres):
    return postgres.init()
  when defined(useSqlite):
    return sqlite.init()
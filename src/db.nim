# Copyright © Louie Quartz 2022
# Licensed under the AGPL version 3 or later.
#
# db.nim  ;;  Database functions

# From pothole
import lib
import conf

# From standard library
import std/[db_sqlite,strutils]

{.gcsafe.}:
  var db*:DbConn;

# Initialize a database depending on its type.
proc init*(dbtype: var string = get("database","type")) =
  dbtype = toLower(dbtype)
  case dbtype:
  of "sqlite":
    # Here we try to open the database
    if exists("database","filename") == false:
      error("No database filename provided","db.init.sqlite")
    db = open(get("database","filename"),"","","")

  else:
    error("Unknown database type (" & dbtype & ")","db.init")

# Initializes the globally shared database connection
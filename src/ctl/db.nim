# Copyright © Leo Gavilieau 2023
# Licensed under the AGPL version 3 or later.
#
# ctl/db.nim:
## Database operations for Potholectl
## This simply parses the subsystem & command (and maybe arguments)
## and it calls the appropriate function from src/db.nim

# From ctl/ folder in Pothole
import shared

# From elsewhere in Pothole
import ../db
from ../lib import error

# From standard libraries
from std/tables import Table


proc processCmd*(cmd: string, data: seq[string], args: Table[string,string]) =
  if checkArgs(args,"h","help"):
    helpPrompt("db",cmd)

  case cmd:
  of "init":
    # Yes, we have initialized the database previously
    # But the user insists that we initialize it again.
    # What a strange world we live in... :)
    # Let's uninitialize first...
    if not db.uninit():
      error "Database uninitialization failed!","ctl/db.processCmd(init)"
    if not db.init(noSchemaCheck=true):
      error "Database initialization failed!","ctl/db.processCmd(init)"
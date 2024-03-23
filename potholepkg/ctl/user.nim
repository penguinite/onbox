# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This file is part of Pothole.
# 
# Pothole is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Pothole is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Pothole. If not, see <https://www.gnu.org/licenses/>. 
#
# ctl/user.nim:
## User-related operations for potholectl
## This simply parses the subsystem & command (and maybe arguments)
## and it calls the appropriate function from potholepkg/database.nim and potholepkg/user.nim

# From ctl/ folder in Pothole
import shared

# From elsewhere in Pothole
import ../[database,lib,conf,user]

# From standard libraries
from std/tables import Table
import std/strutils except isEmptyOrWhitespace

proc processCmd*(cmd: string, data: seq[string], args: Table[string,string]) =
  if args.check("h","help"):
    helpPrompt("user",cmd)

  var config: ConfigTable
  if args.check("c", "config"):
    config = conf.setup(args.get("c","config"))
  else:
    config = conf.setup(getConfigFilename())

  case cmd:
  of "new":
    var
      name = ""
      email = ""
      password = ""
      display = name
      bio = ""

    # Fill up every bit of info we need
    # First the plain command-line mandatory arguments
    echo data
    if len(data) > 2:
      name = data[0]
      email = data[1]
      password = data[2]
    
    # And then the short and long command-line options
    if args.check("n","name"):
      name = args.get("n","name")
    
    if args.check("e","email"):
      email = args.get("e","email")

    if args.check("d", "display"):
      display = args.get("d", "display")
    
    if args.check("p", "password"):
      password = args.get("p", "password")
    
    if args.check("b", "bio"):
      bio = args.get("b", "bio")
    
    # Then we check if our essential data is empty.
    # If it is, then we error out and tell the user to RTFM (but kindly)
    if name.isEmptyOrWhitespace() or email.isEmptyOrWhitespace() or password.isEmptyOrWhitespace():
      log "Invalid command usage"
      log "You can always freshen up your knowledge on the CLI by re-running the same command with -h or --help"
      log "In fact, for your convenience! That's what we will be doing! :D"
      helpPrompt("user", cmd)

    var user = newUser(
      handle = name,
      local = true,
      password = password,
    )

    user.email = email
    user.name = sanitizeHandle(display)
    user.bio = escape(bio)
    user.is_approved = true

    if args.check("a","admin"): user.admin = true
    if args.check("m","moderator"): user.moderator = true
    if args.check("r","require-approval"): user.is_approved = false
    
    if database.setup(config, true).addUser(user):
      log "Successfully inserted user"
      echo "Login details:"
      echo "name: ", user.handle
      echo "email: ", user.email
      echo "password: ", password
    else:
      log "Failed to insert user"
  else:
    helpPrompt("db")
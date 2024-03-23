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
# ctl/post.nim:
## Post-related operations for potholectl
## This simply parses the subsystem & command (and maybe arguments)
## and it calls the appropriate function from potholepkg/database.nim and potholepkg/user.nim

# From ctl/ folder in Pothole
import shared

# From elsewhere in Pothole
import ../[database,lib,conf,post]

# From standard libraries
from std/tables import Table
import std/strutils except isEmptyOrWhitespace, parseBool

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
      sender = ""
      recipients: seq[string] = @[]
      replyto = ""
      content = ""
      date = now()

    # Fill up every bit of info we need
    # First the plain command-line mandatory arguments
    if len(data) == 2:
      sender = data[0]
      content = data[1]
    
    if len(data) == 3:
      replyto = data[1]

    # And then the short and long command-line options
    if args.check("s","sender"):
      sender = args.get("s","sender")
    
    if args.check("m","mentioned"):
      recipients = toSeq(args.get("m","mentioned"))

    if args.check("r", "replyto"):
      replyto = args.get("r", "replyto")
    
    if args.check("p", "password"):
      content = args.get("p", "password")
    
    if args.check("d", "date"):
      date = toDate(args.get("date", "date"))
    
    # Then we check if our essential data is empty.
    # If it is, then we error out and tell the user to RTFM (but kindly)
    if sender.isEmptyOrWhitespace() or content.isEmptyOrWhitespace():
      log "Invalid command usage"
      log "You can always freshen up your knowledge on the CLI by re-running the same command with -h or --help"
      log "In fact, for your convenience! That's what we will be doing! :D"
      helpPrompt("user", cmd)

    var post = newPost(
      sender = sender,
      content = content,
      replyto = replyto,
      recipients = recipients,
      local = true,
      written = date
    )

    # Some extra checks
    # replyto must be an existing post.
    # sender must be an existing user.
    var isSenderId = true
    let db = database.setup(config, true)
    if not db.userIdExists(sender):
      log "Assuming sender is a handle and not an id..."
      if not db.userHandleExists(sender):
        error "Sender doesn't exist in the database at all"
      isSenderId = false
      log "Converting sender's handle into an ID."
      post.sender = db.getIdFromHandle(sender)
    
    if not db.postIdExists(replyto) and not replyto.isEmptyOrWhitespace():
      error "Replyto must be the ID of a pre-existing post."

    if db.addPost(post):
      log "Successfully inserted post"
    else:
      log "Failed to insert user"
  of "delete", "del", "purge":
    var
      thing = ""
      idOrhandle = false # True means it's an id, False means it's a handle.
    if len(data) > 0:
      thing = data[0]
    
    let db = database.setup(config, true)

    if db.userIdExists(thing) and db.userHandleExists(thing) and "@" notin thing:
      error "Potholectl can't infer whether this is an ID or a handle, please re-run with either -i or -n"
    
    # If there's an @ symbol then it's highly likely it's a handle
    if args.check("i", "id"):
      idOrhandle = true
    
    if args.check("n", "name") or "@" in thing:
      idOrhandle = false

    # Try to convert the thing we received into an ID.
    # So it's easier    
    var id = ""
    case idOrhandle:
    of false:
      # It's a handle
      if not db.userHandleExists(thing):
        error "User handle doesn't exist"
      id = db.getIdFromHandle(thing)
    of true:
      # It's an id
      if not db.userIdExists(thing):
        error "User id doesn't exist"
      id = thing
    
    if args.check("p", "purge") or cmd == "purge":
      # Delete every post first.
      if not db.deletePosts(db.getPostIDsByUserWithID(id)):
        error "Failed to delete posts by user"
    
    # Delete the user
    if not db.deleteUser(id):
      error "Failed to delete user"
    
    echo "If you're seeing this then there's a high chance your command succeeded."
  else:
    helpPrompt("db")
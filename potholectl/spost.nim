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

# From somewhere in Quark
import quark/[post, strextra]

# From somewhere in Pothole
import pothole/[database,lib,conf]

# From standard libraries
from std/tables import Table
import std/strutils except isEmptyOrWhitespace, parseBool

proc post_new*(data: seq[string], mentioned = "", replyto = "", date = "", config = "pothole.conf"): int =
  ## This command creates a new post and adds it to the database.
  ## 
  ## Usage: potholectl post new [SENDER] [CONTENT].
  ## Where [SENDER] is a handle and [CONTENT] is anything you would like.
  ## 
  ## Here is an example: potholectl post new john "Hello World!"
  ## 
  ## This command requires that the user's you'll be sending from are real and exist in the database.
  ## Otherwise, you'll be in database hell.
  if len(data) != 2:
    error "Missing number of arguments"
  
  var
    sender, content = ""
    recipients: seq[string]
    written: DateTime = utc(now())
  
  if date != "":
    written = toDateFromDb(date)

  # Fill up every bit of info we need
  # First the plain command-line mandatory arguments
  sender = data[0]
  content = data[1]
  
  # Then we check if our essential data is empty.
  # If it is, then we error out and tell the user to RTFM (but kindly)
  if sender.isEmptyOrWhitespace() or content.isEmptyOrWhitespace():
    error "Sender or content is mostly empty."

  if '@' in sender:
    error "We can't create posts for remote users."

  let
    cnf = config.setup()
    db = setup(
      cnf.getDbName(),
      cnf.getDbUser(),
      cnf.getDbHost(),
      cnf.getDbPass(),
      true
    )

  # Double check that every recipient is real and exists.
  for user in mentioned.smartSplit(','):
    if db.userHandleExists(user):
      recipients.add(db.getIdFromHandle(user))
      continue
    if db.userIdExists(user):
      recipients.add(user)

  var post = newPost(
    sender = sender,
    content = content,
    replyto = replyto,
    recipients = recipients,
    local = true,
    written = written
  )

  # Some extra checks
  # replyto must be an existing post.
  # sender must be an existing user.
  if not db.userIdExists(sender):
    log "Assuming sender is a handle and not an id..."
    if not db.userHandleExists(sender):
      error "Sender doesn't exist in the database at all"
    log "Converting sender's handle into an ID."
    post.sender = db.getIdFromHandle(sender)
  
  if not db.postIdExists(replyto) and not replyto.isEmptyOrWhitespace():
    error "Replyto must be the ID of a pre-existing post."

  try:
    db.addPost(post)
    log "Successfully inserted post"
  except CatchableError as err:
    error "Failed to insert post: ", err.msg

proc processCmd*(cmd: string, data: seq[string], args: Table[string,string]) =
  var config: ConfigTable
  config = conf.setup(getConfigFilename())

  let db = database.setup(
    config.getDbName(),
    config.getDbUser(),
    config.getDbHost(),
    config.getDbPass(),
    true
  )

  case cmd:
  of "new": return
  of "delete", "del":
    if len(data) == 0:
      error "Arguments must be provided for this command to work"
    # TODO: Implement
    echo "If you're seeing this then there's a high chance your command succeeded."
  of "purge":
    # TODO: Implement
    echo "If you're seeing this then there's a high chance your command succeeded."

# TODO: Missing commands:
#   post_del: Deletes a post
#   post_purge: Deletes old posts made by the null (deleted) user.
#   user_mod: Changes a user's moderator status
#   user_admin: Changes a user's administrator status
#   user_password: Changes a user's password
#   user_freeze: Change's a user's frozen status
#   user_approve: Approves a user's registration
#   user_deny: Denies a user's registration
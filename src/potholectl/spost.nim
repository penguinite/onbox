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
import quark/[posts, strextra, db, users, shared]

# From somewhere in Pothole
import pothole/[database,lib,conf]

# From standard libraries
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
    content = @[text(content, written)],
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

proc post_get*(args: seq[string], limit = 10, id = true, handle = false, config = "pothole.conf"): int =
  ## This command displays a user's most recent posts, it only supports displaying text-based posts as of now.
  ## 
  ## You can adjust how many posts will be shown with the `limit` parameter
  if len(args) != 1:
    error "Invalid number of arguments"
  
  var
    thing = args[0]
    isId = id

  # If the user tells us its a handle
  # or if "thing" has an @ symbol
  # then its a handle.
  if not id:
    if handle or "@" in thing:
      isId = false
  
  # If the user supplies both -i and -n then error out and ask them which it is.
  if id and handle:
    error "This can't both be a name and id, which is it?"
  

  if thing.isEmptyOrWhitespace():
    error "Argument is empty"

  let
    cnf = setup(config)
    db = setup(
      cnf.getDbUser(),
      cnf.getDbName(),
      cnf.getDbHost(),
      cnf.getDbPass(),
    )
    
  if db.userIdExists(thing) and db.userHandleExists(thing) and "@" notin thing:
    error "Potholectl can't infer whether this is an ID or a handle, please re-run with the -i or -n flag depending on if this is an id or name"

  # Try to convert the thing we received into an ID.
  # So it's easier to handle
  var id = ""
  case isId:
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

# TODO: Missing commands:
#   post_del: Deletes a post
#   post_purge: Deletes old posts made by the null (deleted) user.
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

# From somewhere in Potholectl
import shared

# From somewhere in Quark
import quark/[database, user, strextra, crypto]

# From somewhere in Pothole
import pothole/[database,lib,conf]

# From standard libraries
from std/tables import Table
import std/strutils except isEmptyOrWhitespace, parseBool

proc new*(args: seq[string], admin = false, moderator = false, require_approval = false, display = "Default Name", bio = "", config = "pothole.conf"): int =
  if len(args) != 3:
    error "Invalid number of arguments, expected 3."

  # Then we check if our essential args is empty.
  # If it is, then we error out
  var
    handle = args[0]
    email = args[1]
    password = args[2]
  if handle.isEmptyOrWhitespace() or password.isEmptyOrWhitespace() or email.isEmptyOrWhitespace():
    error "Required argument is either empty or non-existent."

  let
    cnf = setup(config)
    db = setup(
      cnf.getDbUser(),
      cnf.getDbName(),
      cnf.getDbHost(),
      cnf.getDbPass(),
    )
  
  var user = newUser(
    handle = handle,
    local = true,
    password = password
  )

  user.email = email
  user.name = display
  user.bio = escape(bio)
  user.is_approved = not require_approval
  user.admin = admin
  user.moderator = moderator
    
  try:
    db.addUser(user)
  except CatchableError as err:
    error "Failed to insert user: ", err.msg
  
  log "Successfully inserted user"
  echo "Login details:"
  echo "name: ", user.handle
  echo "password: ", password
  return 0

proc delete*(args: seq[string], purge = false, id = false, name = false, config = "pothole.conf"): int =
  if len(args) != 1:
    error "Invalid number of arguments"
  
  var
    thing = args[0]
    isId = id

  # If the user tells us its a name
  # or if "thing" has an @ symbol
  # then its a name.
  if name or "@" in thing:
    isId = false
  
  # If the user supplies both -i and -n then error out and ask them which it is.
  if id and name:
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
    
  # The `null` user is important.
  # We simply cannot delete it otherwise we will be in database hell.
  if id == "null":
    error "Deleting the null user is not allowed."

  if purge:
    # Delete every post first.
    try:
      db.deletePosts(db.getPostIDsByUserWithID(id))
    except CatchableError as err:
      error "Failed to delete posts by user: ", err.msg
  else:
    # We must reassign every post made this user to the `null` user
    # Otherwise the database will freakout.
    try:
      db.reassignSenderPosts(db.getPostIDsByUserWithID(id), "null")
    except CatchableError as err:
      log "There's probably some database error somewhere..."
      error "Failed to reassign posts by user: ", err.msg
    
  # Delete the user
  try:
    db.deleteUser(id)
  except CatchableError as err:
    error "Failed to delete user: ", err.msg
    
  echo "If you're seeing this then there's a high chance your command succeeded."

proc id*(args: seq[string], quiet = false, config = "pothole.conf"): int = 
  if len(args) != 1:
    if quiet: quit(1)
    error "Invalid number of arguments"
  
  if args[0].isEmptyOrWhitespace():
    if quiet: quit(1)
    error "Empty or mostly empty argument"
  
  let
    cnf = setup(config)
    db = setup(
      cnf.getDbUser(),
      cnf.getDbName(),
      cnf.getDbHost(),
      cnf.getDbPass(),
    )

  if not db.userHandleExists(args[0]):
    if quiet: quit(1)
    error "You must provide a valid user handle to this command"
    
  echo db.getIdFromHandle(args[0])
  return 0

proc handle*(args: seq[string], quiet = false, config = "pothole.conf"): int =
  if len(args) != 1:
    if quiet: quit(1)
    error "Invalid number of arguments"
  
  if args[0].isEmptyOrWhitespace():
    if quiet: quit(1)
    error "Empty or mostly empty argument"
  
  let
    cnf = setup(config)
    db = setup(
      cnf.getDbUser(),
      cnf.getDbName(),
      cnf.getDbHost(),
      cnf.getDbPass(),
    )

  if not db.userIdExists(args[0]):
    if quiet: quit(1)
    error "You must provide a valid user id to this command"
    
  echo db.getHandleFromId(args[0])
  return 0

{.warning[ImplicitDefaultValue]: off.}
proc info*(args: seq[string]; id,handle,display,moderator,admin,request,frozen,email,bio,password,salt,kind,quiet = false, config = "pothole.conf"): int = 
  if len(args) != 1:
    if quiet: quit(1)
    error "Invalid number of arguments"
  
  if args[0].isEmptyOrWhitespace():
    if quiet: quit(1)
    error "Empty or mostly empty argument"
  
  let
    cnf = setup(config)
    db = setup(
      cnf.getDbUser(),
      cnf.getDbName(),
      cnf.getDbHost(),
      cnf.getDbPass(),
    )

  var user: User
  if db.userHandleExists(args[0]):
    if not quiet:
      log "Using provided args as a user handle"
    user = db.getUserByHandle(args[0])
  elif db.userIdExists(args[0]):
    if not quiet:
      log "Using provided args as a user ID"
    user = db.getUserById(args[0])
  else:
    error "No valid user handle or id exists for the provided args..."


  var output = ""
  proc print(s,s2: string) =
    if quiet:
      output.add s2
    else:
      output.add s & ": " & s2

  ## TODO: wtf
  if id: print "ID", user.id
  if handle: print "Handle", user.handle
  if display: print "Display name", user.name
  if admin: print "Admin status", $(user.admin)
  if moderator: print "Moderator status", $(user.admin)
  if request: print "Approval status:", $(user.is_approved)
  if frozen: print "Frozen status:", $(user.is_frozen)
  if email: print "Email", user.email
  if bio: print "Bio", user.bio
  if password: print "Password (hashed)", user.password
  if salt: print "Salt", user.salt
  if kind: print "User type": $(user.kind)

  if output == "":
    echo $user
  else:
    echo output
  return 0
{.warning[ImplicitDefaultValue]: on.}

proc hash*(args: seq[string], algo = "", quiet = false): int =
  if len(args) == 0 or len(args) > 2:
    error "Invalid number of arguments"
    
  var
    password = args[0]
    salt = ""
    kdf = crypto.kdf
  
  if algo != "":
    kdf = StringToKDF(algo)

  if len(args) == 2:
    salt = args[1]
    
  var hash = hash(
    password, salt, kdf
  )

  if quiet:
    echo hash
    return 0

  echo "Hash: \"", hash, "\""
  echo "Salt: \"", salt, "\""
  echo "KDF Id: ", kdf
  echo "KDF Algorithm: ", KDFToHumanString(kdf)

# TODO: Missing commands:
#   hash: Hashes a password
#   mod: Changes a user's moderator status
#   admin: Changes a user's administrator status
#   password: Changes a user's password
#   freeze: Change's a user's frozen status
#   approve: Approves a user's registration
#   deny: Denies a user's registration
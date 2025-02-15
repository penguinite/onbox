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
# potholectl/suser.nim:
## User-related operations for potholectl
## This simply parses the subsystem & command (and maybe arguments)
## and it calls the appropriate function from potholepkg/database.nim and potholepkg/user.nim

# From somewhere in Quark
import quark/[users, strextra, crypto, db, posts]

# From somewhere in Pothole
import pothole/[database,lib,conf]

# From standard libraries
import std/strutils except isEmptyOrWhitespace, parseBool

proc user_new*(args: seq[string], admin = false, moderator = false, require_approval = false, display = "Default Name", bio = "", config = "pothole.conf"): int =
  ## This command creates a new user and adds it to the database.
  ## It uses the following format: NAME EMAIL PASSWORD
  ## 
  ## So to add a new user, john for example, you would run potholectl user new john johns@email.com johns_password
  ## 
  ## The users created by this command are approved by default.
  ## Although that can be changed with the require-approval CLI argument
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

proc user_delete*(args: seq[string], purge = false, id = true, handle = false, config = "pothole.conf"): int =
  ## This command deletes a user from the database, you can either specify a handle or user id.
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
    
  # The `null` user is important.
  # We simply cannot delete it otherwise we will be in database hell.
  if id == "null":
    error "Deleting the null user is not allowed."

  for pid in db.getPostsByUser(id):
    try:
      # If the user says its ok to put extra strain on the db
      # and actually delete the posts made by this user
      # Then we'll do it! Otherwise, we'll just reset the sender to "null"
      # (Which marks it as deleted internally but doesnt do anything.)
      if purge:
        echo "Deleting post \"", pid, "\""
        db.deletePost(pid)
      else:
        echo "Marking post \"", pid, "\" as deleted"
        db.updatePostSender(pid, "null")
    except CatchableError as err:
      error "Failed to process user posts: ", err.msg
    
  # Delete the user
  try:
    db.deleteUser(id)
  except CatchableError as err:
    error "Failed to delete user: ", err.msg
    
  echo "If you're seeing this then there's a high chance your command succeeded."

proc user_id*(args: seq[string], quiet = false, config = "pothole.conf"): int =
  ## This command is a shorthand for user info -i
  ## 
  ## It basically prints the user id of whoever's handle we just got
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

proc user_handle*(args: seq[string], quiet = false, config = "pothole.conf"): int =
  ## This command is a shorthand for user info -h
  ## 
  ## It basically prints the user handle of whoever's id we just got
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

# I hate this just as much as you do but cligen complains without so here goes.
proc user_info*(args: seq[string], id = false, handle = false,
    display = false, moderator = false, admin = false, request = false, frozen = false,
    email = false, bio = false, password = false, salt = false, kind = false,
    quiet = false, config = "pothole.conf"): int = 

  ## This command retrieves information about users.
  ## By default it will display all information!
  ## You can also choose to see specific bits with the command flags
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
  ## This command hashes the given password with the latest KDF function.
  ## You can also customize what function it will use with the algo command flag.
  ## 
  ## Format: potholectl user hash [PASSWORD] [SALT]
  ## 
  ## [PASSWORD] is required, whilst [SALT] can be left out.
  if len(args) == 0 or len(args) > 2:
    error "Invalid number of arguments"
    
  var
    password = args[0]
    salt = ""
    kdf = crypto.latestKdf
  
  if algo != "":
    kdf = toKdfFromDb(algo)

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
  echo "KDF Algorithm: ", toHumanString(kdf)

# TODO: Missing commands:
#   user_mod: Changes a user's moderator status
#   user_admin: Changes a user's administrator status
#   user_password: Changes a user's password
#   user_freeze: Change's a user's frozen status
#   user_approve: Approves a user's registration
#   user_deny: Denies a user's registration
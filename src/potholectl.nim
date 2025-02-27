# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
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
# potholectl:
## Potholectl is a command-line tool that provides a nice and simple interface to many of Pothole's internals.
## It can be used to create new users, delete posts, add new MRF policies, setup database containers and more!
## Generally, this command aims to be a Pothole instance administrator's best friend.
# From Pothole:
import pothole/db/[users, posts, auth_codes]
import pothole/[database, shared, strextra, conf]

# Standard library
import std/[osproc, os, times, strformat, strutils]

# Third-party libraries
import cligen, rng, iniplus, db_connector/db_postgres

## Utility procs first!

proc exec(cmd: string): string {.discardable.} =
  try:
    log "Executing: ", cmd
    let (output,exitCode) = execCmdEx(cmd)
    if exitCode != 0:
      log "Command returns code: ", exitCode
      log "command returns output: ", output
      return ""
    return output
  except CatchableError as err:
    log "Couldn't run command:", err.msg

proc getConfig(c = "pothole.conf"): ConfigTable =
  return iniplus.parseFile(getConfigFilename(c))

proc getDb(c: ConfigTable): DbConn =
  return db_postgres.open(
      c.getDbHost(),
      c.getDbUser(),
      c.getDbPass(),
      c.getDbName(),
    )

## Then the commands themselves!!

proc user_new*(args: seq[string], admin = false, moderator = false, require_approval = false, display = "Default Name", bio = "", config = "pothole.conf"): int =
  ## This command creates a new user and adds it to the database.
  ## It uses the following format: NAME PASSWORD
  ## 
  ## So to add a new user, john for example, you would run potholectl user new "john" "johns_password"
  ## 
  ## The users created by this command are approved by default.
  ## Although that can be changed with the require-approval parameter
  if len(args) != 3:
    error "Invalid number of arguments, expected 3."

  # Then we check if our essential args is empty.
  # If it is, then we error out
  for i in 0..1:
    if args[i].isEmptyOrWhitespace():
      error "Required argument is either empty or non-existent."

  let
    cnf = getConfig(config)
    db = getDb(cnf)
  
  var user = newUser(
    handle = args[0],
    local = true,
    password = args[1]
  )

  user.email = ""
  user.name = display
  user.bio = bio
  user.admin = admin
  user.moderator = moderator

  user.is_approved = false
  if cnf.getBoolOrDefault("user", "require_approval", false) or require_approval:
    user.is_approved = true
    
  try:
    db.addUser(user)
  except CatchableError as err:
    error "Failed to insert user: ", err.msg
  
  log "Successfully inserted user"
  echo "Login details:"
  echo "name: ", user.handle
  echo "password: ", args[1]

proc user_delete*(args: string, purge = false, config = "pothole.conf"): int =
  ## This command deletes a user from the database, you must supply a handle.
  if len(args) != 1:
    error "No handle given"
  
  if args[0].isEmptyOrWhitespace():
    error "Handle given is mostly empty"

  let db = getConfig(config).getDb()
    
  if not db.userHandleExists(thing):
    error "User doesn't exist"

  # Try to convert the thing we received into an ID.
  # So it's easier to handle
  var id = db.getIdFromHandle(thing)
    
  # The `null` user is important.
  # We simply cannot delete it otherwise we will be in database hell.
  if id == "null":
    error "Deleting the null user is not allowed."

  for pid in db.getPostsByUser(id):
    try:
      # If it's ok to put extra strain on the db
      # and actually delete the posts made by this user
      # Then we'll do it! Otherwise, we'll just reset the sender to "null"
      # (Which marks it as deleted internally but
      # doesnt do anything particularly intense.)
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

# I hate this just as much as you do but it's whatever.
{.warning[ImplicitDefaultValue]: off.}
proc user_info*(args: seq[string], id,handle,display,moderator,admin,request,frozen,email,bio,password,salt,kind,quiet = false, config = "pothole.conf"): int = 

  ## This command retrieves information about users.
  ## By default it will display all information!
  ## You can also choose to see specific bits with the command flags
  if len(args) != 1:
    if quiet: quit(1)
    error "Invalid number of arguments"
  
  if args[0].isEmptyOrWhitespace():
    if quiet: quit(1)
    error "Empty or mostly empty argument"
  
  let db = getConfig(config).getDb()

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

  if output == "": echo $user
  else: echo output
{.warning[ImplicitDefaultValue]: on.}

# TODO: Missing commands:
#   user_id: When given a full handle, return the database ID of that user.
#   user_handle: When given an ID, return the full handle of that user
#   user_mod: Promote (or demote) a user into a moderator.
#   user_admin: Promote (or demote) a user into an administrator.
#   user_password: Changes a users password
#   user_freeze: Freeze (or unfreeze) a user, preventing them from doing anything.
#   user_approve: Approves a users registration
#   user_deny: Denies a users registration

# TODO: Missing commands:
#   post_new: Creates a post from CLI
#   post_get: Returns the most recent posts of a single user
#   post_delete: Deletes a post
#   post_purge: Deletes old posts made by the null (deleted) user.
#    (This could maybe be added to the db vaccuum command? as an option)

proc db_setup(config = "pothole.conf", location = ""): int =
  ## Returns a postgresql script that fully prepares the database,
  ## including setting the right permissions and setting up the user.
  ## This is the recommended way to setup your database server for Pothole.
  let
    cnf = getConfig(config)
    user = cnf.getDbUser()
    name = cnf.getDbName()
    password = cnf.getDbPass()
  
  var output = fmt"""
CREATE USER {user} WITH PASSWORD '{password}';
CREATE DATABASE {name} WITH OWNER {user};
GRANT ALL PRIVILEGES ON DATABASE {name} TO {user};
\c {name};
GRANT ALL ON SCHEMA public TO {user};
"""

  output.add(staticRead("assets/setup.sql"))
  
  # Allow user to specify location where we can save file.
  # Instead of outputting it directly.
  if location != "":
    writeFile(location, output)
  else:
    echo output

proc db_purge(config = "pothole.conf"): int =
  ## This command purges the entire database, it removes all tables and all the data within them.
  ## It's quite obvious but this command will erase any data you have, so be careful.
  log "Cleaning everything in database"
  getConfig(config).getDb().exec(staticRead("assets/purge.sql"))

proc db_docker(config = "pothole.conf", name = "potholeDb", allow_weak_password = false, expose_externally = false, ipv6 = false): int =
  ## This command is mostly used by the Pothole developers, it's nothing but a simple wrapper over the docker command.
  ## 
  ## This command creates a postgres docker container that automatically works with pothole.
  ## It reads the configuration file and takes note of the database configuration.
  ## And then it pulls the alpine:postgres docker image, and starts it up with the correct port, name, password anything.
  ## 
  ## If this command detects that you are using the default password ("SOMETHING_SECRET") then it will change it to an autogenerated 64 char length password for security's sake.
  ## In most cases, this behavior is perfectly acceptable and fine. But you can disable it with the -a or --allow-weak-password option.
  let cnf = getConfig(config)
  log "Setting up postgres docker container according to config file"
  var
    # Sick one liner to figure out the port we need to expose.
    port = split(getDbHost(cnf), ":")[high(split(getDbHost(cnf), ":"))]
    password = cnf.getDbPass()
    dbname = cnf.getDbName()
    user = cnf.getDbUser()
    host = ""

  if port.isEmptyOrWhitespace():
    port = "5432"
    
  if not expose_externally:
    if ipv6: host.add("::1:")
    else: host.add("127.0.0.1:")
  host.add(port & ":5432")
    
  if password == "SOMETHING_SECRET" and not allow_weak_password:
    log "Changing weak database password to something more secure"
    password = randstr(64)
    echo "Please update the config file to reflect the following changes:"
    echo "[db] password is now \"", password, "\""
  
  log "Pulling docker container"
  discard exec "docker pull postgres:alpine"
  log "Creating the container itself"
  if exec("docker run --name $# -d -p $# -e POSTGRES_USER=$# -e POSTGRES_PASSWORD=$# -e POSTGRES_DB=$# postgres:alpine" % [name, host, user, password, dbname]) == "":
    error "Please investigate the above errors before trying again."

proc db_clean*(config = "pothole.conf"): int =
  ## This command runs some cleanup procedures.
  let
    cnf = getConfig(config)
    db = getDb(cnf)

  log "Cleaning up old sessions"
  for session in db.cleanSessionsVerbose():
    log "Cleaned up session belonging to \"", db.getHandleFromId(session[1]), "\""
  log "Cleaning up expired authentication codes"
  db.cleanupCodes()

dispatchMulti(
  [user_new,
    help = {
      "admin": "Makes the user an administrator",
      "moderator": "Makes the user a moderator",
      "require-approval": "Turns user into an unapproved user",
      "display": "Specifies the display name for the user",
      "bio": "Specifies the bio for the user",
      "config": "Location to config file"
    }],

  [user_delete,
    help = {
      "id": "Specifies whether or not the thing provided is an ID",
      "handle": "Specifies whether or not the thing provided is an handle",
      "purge": "Whether or not to delete all the user's posts and other data",
      "config": "Location to config file"
    }],

  [user_info,
    help = {
      "quiet": "Makes the program a whole lot less noisy. Great for scripting",
      "id":"Print only user's ID",
      "handle":"Print only user's handle",
      "display":"Print only user's display name",
      "admin": "Print user's admin status",
      "moderator": "Print user's moderator status",
      "request": "Print user's approval request",
      "frozen": "Print user's frozen status",
      "email": "Print user's email",
      "bio":"Print user's biography",
      "password": "Print user's password (hashed)",
      "salt": "Print user's salt",
      "kind": "Print the user's type/kind",
      "config": "Location to config file"
    }],

  [db_clean, help = {"config": "Location to config file"}],
  [db_purge, help = {"config": "Location to config file"}],
  [db_docker,
    help= {
      "config": "Location to config file",
      "name": "Sets the name of the database container",
      "allow_weak_password": "Does not change password automatically if its weak",
      "expose_externally": "Potentially expose the database container to the outside world",
      "ipv6": "Sets some IPv6-specific options in the container"
    }],

  [db_setup,
    help = {
      "config": "Location to config file",
      "location": "If specified, potholectl will save the script to this location instead of echoing it"
    }]
)

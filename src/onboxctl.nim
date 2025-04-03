# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This file is part of Onbox.
# 
# Onbox is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Onbox is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Onbox. If not, see <https://www.gnu.org/licenses/>. 
#
# onboxctl:
## onboxctl is a command-line tool that provides a nice and simple interface to many of Onbox's internals.
## It can be used to create new users, delete posts, add new MRF policies, setup database containers and more!
## Generally, this command aims to be a Onbox instance administrator's best friend.
# From Onbox:
import onbox/db/[users, posts, auth_codes, sessions, email_codes]
import onbox/[database, shared, conf]

# Standard library
import std/[osproc, times, strformat, strutils]

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

proc getConfig(c = "onbox.conf"): ConfigTable =
  return iniplus.parseFile(getConfigFilename(c))

proc getDb(c: ConfigTable): DbConn =
  return db_postgres.open(
      c.getDbHost(),
      c.getDbUser(),
      c.getDbPass(),
      c.getDbName(),
    )

## Then the commands themselves!!

proc user_new*(args: seq[string], admin = false, moderator = false, approved = false, display = "Default Name", bio = "", config = "onbox.conf"): int =
  ## This command creates a new user and adds it to the database.
  ## It uses the following format: NAME PASSWORD
  ## 
  ## So to add a new user, john for example, you would run onboxctl user new "john" "johns_password"
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

  if admin: user.roles.add(3)
  if moderator: user.roles.add(2)
  if approved: user.roles.add(1)
    
  try:
    db.addUser(user)
  except CatchableError as err:
    error "Failed to insert user: ", err.msg
  
  log "Successfully inserted user"
  echo "username: ", user.handle
  echo "password: ", args[1]

proc user_delete*(handle: string, purge = false, config = "onbox.conf"): int =
  ## This command deletes a user from the database, you must supply a handle.
  let db = getConfig(config).getDb()
    
  var domain = ""
  # Figure out the domain (if it has one)
  if '@' in handle:
    domain = handle.split('@')[1]

  if not db.userHandleExists(handle, domain):
    error "User \"", handle, "\" doesn't exist, thus, can't delete."

  # Try to convert the thing we received into an ID.
  # So it's easier to handle
  var id = db.getIdFromHandle(handle, domain)
    
  # The `null` user is important.
  # We simply cannot delete it otherwise we will be in database hell.
  if id == "null" or handle == "null":
    error "Deleting the null user is not allowed."

  # Now! Delete the user
  try:
    db.deleteUser(id)
  except CatchableError as err:
    error "Failed to delete user: ", err.msg

  # If it's ok to put extra strain on the db
  # and actually delete the posts made by this user
  # Then we'll do it! Otherwise, we'll just reset the sender to "null"
  if purge:
    for post in db.getPostsByUser(id):
      db.deletePost(post)

# I hate this just as much as you do but it's whatever.
proc user_info*(args: seq[string], id = false, handle = false, display = false, moderator = false, admin = false, request = false, frozen = false, email = false, bio = false, password = false, salt = false, quiet = false, config = "onbox.conf"): int = 
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
  if admin: print "Admin status", $(3 in user.roles)
  if moderator: print "Moderator status", $(2 in user.roles)
  if request: print "Approval status", $(1 in user.roles)
  if frozen: print "Frozen status", $(-1 in user.roles)
  if email: print "Email", user.email
  if bio: print "Bio", user.bio
  if password: print "Password (hashed)", user.password
  if salt: print "Salt", user.salt

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
#    (This could maybe be added to the db_clean command? as an option)

proc db_setup(config = "onbox.conf", location = ""): int =
  ## Returns a postgresql script that fully prepares the database,
  ## including setting the right permissions and setting up the user.
  ## This is the recommended way to setup your database server for Onbox.
  let
    cnf = getConfig(config)
    user = cnf.getDbUser()
    name = cnf.getDbName()
    password = cnf.getDbPass()
  const setupSql = staticRead("assets/setup.sql")
  var output = fmt"""
CREATE USER {user} WITH PASSWORD '{password}';
CREATE DATABASE {name} WITH OWNER {user};
GRANT ALL PRIVILEGES ON DATABASE {name} TO {user};
\c {name};
GRANT ALL ON SCHEMA public TO {user};

""" & setupSql

  # Allow user to specify location where we can save file.
  # Instead of outputting it directly.
  if location != "":
    writeFile(location, output)
  else: echo output

proc db_purge(config = "onbox.conf"): int =
  ## This command purges the entire database, it removes all tables and all the data within them.
  ## It's quite obvious but this command will erase any data you have, so be careful.
  log "Cleaning everything in database"
  const purgeSql = staticRead("assets/purge.sql")
  getConfig(config).getDb().exec(sql(purgeSql))

proc db_docker(config = "onbox.conf", name = "onboxDb", allow_weak_password = false, expose_externally = false, ipv6 = false): int =
  ## This command is mostly used by the Onbox developers, it's nothing but a simple wrapper over the docker command.
  ## 
  ## This command creates a postgres docker container that automatically works with onbox.
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

proc db_clean*(config = "onbox.conf"): int =
  ## This command runs some cleanup procedures.
  let db = getConfig(config).getDb()
  log "Cleaning up old sessions"
  db.cleanSessions()
  log "Cleaning up expired authentication codes"
  db.cleanAuthCodes()
  log "Cleaning up expired email codes"
  db.cleanEmailCodes()
  log "Deleting followers and followings involving nonexistent users"
  db.exec(sql"DELETE FROM user_follows WHERE follower = 'null';")
  db.exec(sql"DELETE FROM user_follows WHERE following = 'null';")
  log "Deleting reactions from nonexistent users"
  db.exec(sql"DELETE FROM reactions WHERE uid = 'null';")
  log "Deleting boosts from nonexistent users"
  db.exec(sql"DELETE FROM boosts WHERE uid = 'null';")
  log "Deleting bookmarks from nonexistent users"
  db.exec(sql"DELETE FROM bookmarks WHERE uid = 'null';")

dispatchMulti(
  [user_new,
    help = {
      "admin": "Make the user an administrator",
      "moderator": "Make the user a moderator",
      "approved": "Approve the user",
      "display": "Specifies the display name for the user",
      "bio": "Specifies the bio for the user",
      "config": "Location to config file"
    }],

  [user_delete,
    help = {
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
      "location": "If specified, onboxctl will save the script to this location instead of echoing it"
    }]
)

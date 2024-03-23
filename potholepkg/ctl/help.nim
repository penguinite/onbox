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
# ctl/help.nim:
## Contains help dialogs for all subsystems and commands
## In potholectl.

#! This is a god damn mess.

from ../lib import version
import std/[tables, strutils]

const prefix* = """
Potholectl $#
Copyright (c) Leo Gavilieau 2023
Copyright (c) penguinite <penguinite@tuta.io> 2024
Licensed under the GNU Affero GPL License under version 3 or later.
""" % [lib.version]

func genArg(short,long,desc: string): string =
  var i = 15
  result = "-" & short & ",--" & long
  i = i - len(result)
  for x in 0..i:
    result.add(' ')
  result.add(";; " & desc)
  return result

func genCmd(cmd,desc: string): string =
  var i = 20
  i = i - len(cmd)
  result.add(cmd)
  for x in 0..i:
    result.add(' ')
  result.add("-- " & desc)
  return result

const helpDialog* = @[
  prefix,
  "Available subsystems: ",
  genCmd("db","Database-related operations"),
  genCmd("mrf","MRF-related operations"),
  genCmd("dev","Local development operations"),
  genCmd("post", "Post-related operations"),
  genCmd("user", "User-related operations"),
  "",
  "Universal arguments: ",
  genArg("h","help","Displays help prompt for any given command and exits."),
  genArg("v","version","Display a version prompt and exits"),
]

const devEnvVarNotice = """
Note: *Environment variables are generated from the config file in the root directory.*
If a config file cannot be found then potholectl will simply use default values.
"""

# This table contains help info for every file.
# It follows the format of SUBSYSTEM:COMMAND
# So fx. if you wanted to see what the
# "potholectl db init" command does then you'd use
# echo($helpTable["db:init"])
# If you wanted to see all the commands of the db subsystem
# then you would use "db" as it is
const helpTable*: Table[string, seq[string]] = {
  "db": @[
    prefix,
    "Available commands:",
    genCmd("schema_check","Checks the database schema against the hardcoded values"),
    genCmd("init", "Initializes the database according to config values")
  ],

  "db:schema_check": @[
    prefix,
    "This command initializes a database with schema checking enabled.",
    "You can use it to test if the database needs migration.",
    "Available arguments:",
    genArg("c","config","Specify a config file to use")
  ],

  "db:init": @[
    prefix,
    "This command initializes a database with schema checking enabled.",
    "You can use it to test if the database needs migration.",
    "Available arguments:",
    genArg("c","config","Specify a config file to use")
  ],

  "mrf": @[
    prefix,
    """
This subsystem handles "Extensions"/"Plugins" related operations.
Certain features in Pothole are extensible at run-time and this subsystem 
is there specifically to aid with debugging, enabling and making use of this

If its unclear what these commands do then, you should read the docs.
As some of them change the config file, which might or might not break stuff.

Available commands:
    """,
    genCmd("view", "Views information about a specific module."),
    genCmd("config_config", "Checks the config file for any errors related to extensions.")
  ],

  "mrf:view": @[
    prefix,
  """
This command reads a custom MRF policy and shows its metadata.
You should supply the path to the module for this command, it does not
read the config file.

Available arguments:
  """,
    genArg("t","technical","Show non-human-friendly metadata. Ie. Technical data.")
  ],

  "mrf:config_check": @[
    prefix,
    """
This command reads the config file and checks if the "MRF" section is valid.
It does not make any changes, it merely points out errors and potential fixes.

Available arguments:
  """,
    genArg("c","config","Path to configuration file.")
  ],

  "dev": @[
    prefix,
    """
This subsystem is specifically intended for developers, it helps create postgres
containers for local development and stuff.
Right now this only supports docker, I might add podman support later.
    """,
    devEnvVarNotice,
    """
Available commands:
    """,
    genCmd("setup", "Initializes everything for local development"),
    genCmd("db", "Creates a postgres container for local development"),
    genCmd("env", "Initializes environment variables and also deletes them."),
    genCmd("clean", "Removes all tables inside of a postgres database container"),
    genCmd("purge", "Cleans up everything, including images, envvars and build folders"),
    genCmd("psql", "Opens a psql shell inside of the docker container"),
    genCmd("delete", "Deletes the postgres container (basically potholectl dev db -d)")
  ],

  "dev:setup": @[
    prefix,
    """
This command basically just runs every setup command. It creates containers,
initializes environment variables and everything else it needs.
    """,
    devEnvVarNotice
  ],

  "dev:db": @[
    prefix,
    """
This command only initializes the database container, it only supports Docker.
Might add podman support later, idk.

Available arguments:
    """,
    genArg("d","delete","Deletes the postgres container")
  ],

  "dev:env": @[
    prefix,
    """
This command only initializes the environment variables required for Pothole
to read the database, so like, it creates PHDB_HOST, PHDB_USER, PHDB_NAME and PHDB_PASS.
You can unset the environment variables by supplying the "delete" option.
    """,
    devEnvVarNotice,
    "Available arguments: ",
    genArg("d","delete","Unsets environment variables")
  ],

  "dev:clean": @[
    prefix,
    """
This command clears every table inside the postgres container, useful for when
you need a blank slate inbetween tests.

Available arguments:
    """
  ],

  "dev:purge": @[
    prefix,
    """
This command purges everything, everything from environment variables to container
images to build folders. Only use this if you need a really, *really* blank slate.
Running this inbetween tests is very wasteful as it also removes the container
image.
    """
  ],
  "dev:psql": @[
    prefix,
    """
This command opens a psql shell in the database container. This is useful for 
debugging operations and generally figuring out where we went wrong.
    """
  ],
  "dev:delete": @[
    prefix,
    """
This command basically does the same thing as potholectl dev db -d.
It deletes the database docker container.
    """
  ],
  "user": @[
    """
This subsystem contains user-related operations, it has command for adding new users, deleting old ones.
And so on, and so forth.
    """,
    devEnvVarNotice,
    """
Available commands:
    """,
    genCmd("new", "Creates a new user and adds it to the database"),
    genCmd("delete", "Deletes specified user"),
    genCmd("del", "(Shorthand for delete)"),
    genCmd("purge", "(Shorthand for delete -p)"),
    genCmd("change", "A generic user modification command."),
    genCmd("mod", "Changes a user's moderator status"),
    genCmd("admin", "Changes a user's administrator status"),
    genCmd("password", "Changes a user's password"),
    genCmd("pw", "(Shorthand for password)"),
    genCmd("freeze", " Change's a user's frozen status"),
    genCmd("approve", "Approves a user's registration"),
    genCmd("deny", "Denies a user's registration")
  ],
  "user:new": @[
    prefix,
    """
This command creates a new user and adds it to the database.
It uses the following format: NAME EMAIL PASSWORD
Here is an example of a valid new user command: potholectl user new john johnson@world.gov johns_password123

The users created by this command are approved by default.
Although that can be changed with the require-approval CLI argument

You can also use the following command-line arguments:
    """,
    genArg("a","admin","Makes the user an administrator"),
    genArg("m","moderator", "Makes the user a moderator"),
    genArg("r","require-approval","Requires approval for the user"),
    genArg("n","name", "Specifies the username [Value required]"),
    genArg("e","email", "Specifies the user's email [Value required]"),
    genArg("d","display", "Specifies the user's display name [Value required]"),
    genArg("p","password", "Specifies the user's password [Value required]"),
    genArg("b","bio", "Specifies the user's biography [Value required]")
  "post": @[
    prefix,
    """
This subsystem has post-related commands, fx. you can create posts and add them to the database.
Or you can delete posts, and so on and so forth.

The following commands are available:
    """,
    genCmd("new", "Creates a new post and adds it to the database"),
    genCmd("delete", "Deletes a post from the database"),
    genCmd("del", "(Shorthand for delete)")
  ],
  "post:new": @[
    prefix,
    """
This command creates a new post and adds it to the database.
By default, it follows this format: SENDER [REPLYTO] CONTENT
(REPLYTO is optional and can be omitted.)
Here is an example: potholectl post new john "Hello World!"
And here is another potholectl post new john2 "Hello John!"

This command requires that the user's you'll be sending from are real and exist in the database.
Otherwise, you'll be in database hell.

This commad has the following arguments:
      """,
      genArg("s","sender", "Specifies the sender of the post"),
      genArg("m","mentioned", "Specifies the list of people mentioned (Comma-separated)"),
      genArg("r", "replyto", "Specifies the post we are replying to"),
      genArg("c", "content", "Specifies the post's contents"),
      genArg("d","date", "Specifies the date of the post (See: potholectl date)")
  ],
}.toTable

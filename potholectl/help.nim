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

from pothole/lib import version
import std/[tables, strutils]

const prefix* = """
Potholectl $#
Copyright (c) Leo Gavilieau 2023
Copyright (c) penguinite 2024
Licensed under the GNU Affero GPL License under version 3 or later.
""" % [lib.phVersion]

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
  "",
  "There are also some extra helpful educational help prompts just incase you get stuck on something!",
  genCmd("date", "Information about how pothole handles date parsing"),
  genCmd("handles", "Information about user handles"),
  genCmd("ids", "Information about user IDs")
]

const devEnvVarNotice = """
Note: *Environment variables are generated from the config file in the current directory.*
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
    genCmd("info", "Displays generic information about the provided user."),
    genCmd("id", "Gets the user ID when given a handle"),
    genCmd("handle", "Gets the handle when given a user ID"),
    genCmd("hash", "Hashes a password"),
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
It uses the following format: NAME PASSWORD
Here is an example of a valid new user command: potholectl user new john johns_password123

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
  ],
  "user:delete": @[
    prefix,
    """
This command deletes a user from the database, you can either specify a handle or user id.

You can also use the following command-line arguments:
    """,
    genArg("n","name", "Supply a username to be deleted [Value Required]"),
    genArg("i","id", "Supply an ID to be deleted [Value Required]"),
    genArg("p","purge", "Purge everything from this user")
  ],
  "user:del": @[
    prefix,
    "This command is an alias to the delete command"
  ],
  "user:purge": @[
    prefix,
    "This command is an alias to the delete command with the purge flag"
  ],
  "user:id": @[
    prefix,
    "This command is a shorthand for user info -i",
    "It basically prints the user id of whoever's handle we just got",
    "",
    "The following arguments are available:",
    genArg("q","quiet", "Makes the program a whole lot less noisy.")
  ],
  "user:handle": @[
    prefix, 
    "This command is a shorthand for user info -h",
    "It basically prints the user handle of whoever's id we just got",
    "",
    "The following arguments are available:",
    genArg("q","quiet", "Makes the program a whole lot less noisy.")
  ],
  "user:info": @[
    prefix,
    """
This command retrieves information about users.
By default it will display all information!
You can also choose to see specific bits with these flags:
    """,
    genArg("q","quiet", "Makes the program a whole lot less noisy."),
    genArg("i","id","Print only user's ID"),
    genArg("h","handle","Print only user's handle"),
    genArg("d","display","Print only user's display name"),
    genArg("a","admin", "Print user's admin status"),
    genArg("m","moderator", "Print user's moderator status"),
    genArg("r","request", "Print user's approval request"),
    genArg("f","frozen", "Print user's frozen status"),
    genArg("e","email", "Print user's email"),
    genArg("b","bio","Print user's biography"),
    genArg("p","password", "Print user's password (hashed)"),
    genArg("s","salt", "Print user's salt"),
    genArg("t","type", "Print user type")
  ],
  "user:hash": @[
    prefix, 
    """
Format: potholectl user hash [PASSWORD] [SALT]
[PASSWORD] is required, whilst [SALT] can be left out.

This command hashes the given password with the latest KDF function.
You can also customize what function it will use with the KDF parameter.

The following parameters are available:  
    """,
    genArg("q","quiet", "Makes the program a whole lot less noisy."),
    genArg("k","kdf", "Specifies the KDF function to use when hashing. [Value required]")
  ],
  "post": @[
    prefix,
    """
This subsystem has post-related commands, fx. you can create posts and add them to the database.
Or you can delete posts, and so on and so forth.

The following commands are available:
    """,
    genCmd("new", "Creates a new post and adds it to the database"),
    genCmd("delete", "Deletes a post from the database"),
    genCmd("del", "(Shorthand for delete)"),
    genCmd("id", "Allows you to identify a post very easily"),
    genCmd("purge", "Purges old posts by deleted users")
  ],
  "post:delete": @[
    prefix,
    """
When given a post ID, this command will try to delete it.
Fx. potholectl post delete POST_ID_HERE
    """
  ],
  "post:del": @[
    prefix,
    "This command is an alias to the delete command"
  ],
  "post:purge": @[
    prefix,
    "Purge deletes old posts made by deleted users, more specifically it deletes any post made by the \"null\" user"
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

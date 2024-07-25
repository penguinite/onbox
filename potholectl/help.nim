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

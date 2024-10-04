# Copyright © penguinite 2024 <penguinite@tuta.io>
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
# quark/new/post.nim:
## This module contains all the logic for handling posts.
## 
## Including basic processing, database storage,
## database retrieval, modification, deletion and so on
## and so forth.

import quark/new/[strextra, shared]
import quark/private/macros
import std/[tables, times]
from std/strutils import split
import db_connector/db_postgres

const postsContentCols* = @[
  # The post ID
  "pid TEXT PRIMARY KEY NOT NULL",
  # The specific kind of content it is
  "kind smallint NOT NULL DEFAULT 0",
  # The "id" for the content, if applicable.
  "cid TEXT",
  # Some foreign keys for integrity
  "foreign key (pid) references posts(id)"
]

const postsTextCols* = @[
  # The post id that the best belongs to
  "pid TEXT PRIMARY KEY NOT NULL",
  # The content itself
  "content TEXT NOT NULL",
  # The date that content was published
  "published TIMESTAMP NOT NULL",
  # Whether or not this is the latest post
  "latest BOOLEAN NOT NULL DEFAULT TRUE",
  # Some foreign keys for integrity
  "foreign key (pid) references posts(id)"
]

const postsCols* = @[
  # The Post id
  "id TEXT PRIMARY KEY NOT NULL", 
  # A comma-separated list of recipients since postgres arrays are a nightmare.
  "recipients TEXT",
  # A string containing the sender's id
  "sender TEXT NOT NULL", 
  # A string containing the post that the sender is replying to, if at all.
  "replyto TEXT DEFAULT ''", 
  # A timestamp containing the date that the post was originally written (and published)
  "written TIMESTAMP NOT NULL", 
  # A boolean indicating whether the post was modified or not.
  "modified BOOLEAN NOT NULL DEFAULT FALSE", 
  # A boolean indicating whether the post originated from this server or other servers.
  "local BOOLEAN NOT NULL", 
  # The client that sent the post
  "client TEXT NOT NULL DEFAULT '0'",
  # The "level" for the post, the level dictates
  # who is allowed to see the post and whatnot.
  # such as for example, if it is a direct message.
  "level smallint NOT NULL DEFAULT 0",

  # Foreign keys for database integrity
  "foreign key (sender) references users(id)",
  "foreign key (client) references apps(id)"
]

# Game plan when inserting a post:
# Insert the post
# Insert the post content
#
# Game plan when post is edited (text only):
# Create a new "text content" row in the db
# Update any other columns accordingly (Setting latest to false)
# Create a new "post content" row in the db and set it accordingly.
# Update any other attributes accordingly (For example, the client, the modified bool, the recipients, the level)
# 
# Game plan when post is edited (For non-archived types of content, such as polls):
# Remove existing content row
# Create new one
# 
# 

proc constructPost*(db: DbConn, row: Row): Post =
  ## Converts a post minimally.
  ## This means no reactions list, no boost list
  ## and no post content.
  ## 
  ## If you need all those bits of data then use constructPostFull() instead.
  ## 
  ## If you need *just* the post and its content then use constructPostSemi() instead.
  
  var i: int = -1;

  for key,value in result.fieldPairs:
    # Skip the fields that are processed by *other* bits of code.
    when result.get(key) isnot Table[string, seq[string]] and result.get(key) isnot seq[PostContent]:
      inc(i)

    when result.get(key) is bool:
      result.get(key) = parseBool(row[i])
    when result.get(key) is string:
      result.get(key) = row[i]
    when result.get(key) is seq[string]:
      result.get(key) = split(row[i], ",")

      # the split() proc sometimes creates items in the sequence
      # even when there isn't. So this bit of code manually
      # clears the list if two specific conditions are met.
      if len(result.get(key)) == 1 and result.get(key)[0] == "":
        result.get(key) = @[]
    when result.get(key) is DateTime:
      result.get(key) = toDateFromDb(row[i])
    when result.get(key) is PostPrivacyLevel:
      result.get(key) = toPrivacyLevelFromDb(row[i])
  return result

proc constructPostSemi*(db:DbConn, row: Row): Post =
  result = db.constructPost(row)
  return result


proc constructPostFull*(db: DbConn, row: Row): Post =
  result = db.constructPostSemi(row)
  #result.reactions = db.getReactions(result.id)
  #result.boosts = db.getBoosts(result.id)
  return result


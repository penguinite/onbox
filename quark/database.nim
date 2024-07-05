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
# database.nim:
## Database backend for pothole, this engine is powered via postgres
## (more specifically, the standard db_connector/db_postgres module)
## This backend is still not working yet.

# From somewhere in Quark
import private/database

# From somewhere in Pothole
import user

# From somewhere in the standard library
import std/strutils

# Export these:
import db/[users, posts, reactions, boosts, postrevisions, apps, follows]
export DbConn, users, posts, reactions, boosts, postrevisions, apps, follows

const databaseTables = @[
  ## Add an extra field to this whenever you need to insert a new table.
  ## + cleanDb() depends on this! So no need to add a new table there!
  ("users", usersCols),
  ("posts", postsCols),
  ("postsRevisions", postsRevisionsCols),
  ("reactions", reactionsCols),
  ("boosts", boostsCols),
  ("apps", appsCols),
  ("follows", followsCols)
]

proc setup*(
  name, user, host, password: string,
  schemaCheck: bool = true
): DbConn =

  if host.startsWith("__eat_flaming_death"):
    # This bit of code is used in some documentation, and so its important for us to add a special case
    # so it wont actually run any database operations.
    # TODO: Figure out what documentation is using this workaround, and patch it.
    return

  # Open database
  result = open(host, user, password, name)
  
  # Let's first set some standard settings
  result.exec(sql"SET client_encoding = 'UTF8';")
  result.exec(sql"SET standard_conforming_strings = on;")

  # Here we create the structures.
  for i in databaseTables:
    # Create the tables first
    createDbTable(result, i[0], i[1])
    
    # Now we check the schema to make sure it matches the hard-coded one.
    if schemaCheck:
      matchTableSchema(result, i[0], i[1])
  
  # Add `null` user
  # `null` is used by pothole to signify a deleted user.
  # Fx. imagine a user deletes their account, the database schema requires that we 
  # have a valid sender in every single post.
  # And so `null` acts a sender in that scenario.
  var null = newUser(
    "null",
    true,
    ""
  )
  # The `null` user must have a "null" id.
  null.id = "null"
  null.is_frozen = true
  null.salt = ""
  null.name = "Deleted User"
  if not result.userIdExists("null"):
    result.addUser(null)

  # Add a default app just in case
  if not result.clientExists("0"):
    result.createClient(
      "0", "", ""
    )
  
  # Create an index on the post table to speed up post by user searches.
  result.exec "CREATE INDEX IF NOT EXISTS snd_idx ON posts USING btree (sender);"
  return result

proc init*(name, user, host, password: string): DbConn = 
  ## This procedure quickly initializes the database by skipping a bunch of checks.
  ## It assumes that you have done these checks on startup by running the regular setup() proc once.
  return open(host, user, password, name,)

proc uninit*(db: DbConn): bool =
  ## Uninitialize the database.
  ## Or close it basically...
  db.close()

proc cleanDb*(db: DbConn) =
  for i in databaseTables:
    db.exec(sql("DROP TABLE IF EXISTS " & i[0] & " CASCADE;"))
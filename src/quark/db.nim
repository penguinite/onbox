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

# From somewhere in the standard library
import std/strutils

# Store each column like this: {"COLUMN_NAME":"COLUMN_TYPE"}

# In the past, we used an archaic and sorta messed up system for making
# the tables, these have been replaced with a plain old SQL script that gets read
# at compile-time.
#
# Unlike Pleroma, Pothole's config is entirely stored in the config file.
# There is no way to configure Pothole from the database alone.
# So we do not need a tool to generate SQL for a specific instance.
const
  initSql = staticRead("setup.sql")
  purgeSql = staticRead("purge.sql")

proc setup*(name, user, host, password: string,schemaCheck: bool = true): DbConn =
  ## Runs a setup procedure for the database, useful for ensuring that everything is ready.
  if host.startsWith("__eat_flaming_death"):
    # This bit of code is used in some documentation, and so its important for us to add a special case
    # so it wont actually run any database operations.
    # TODO: Figure out what documentation is using this workaround, and patch it. So that it doesn't run at all.
    return

  # Open database and execute the initSql commands.
  result = open(host, user, password, name)
  result.exec(sql(initSql))
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
  result.exec(sql(purgeSql))
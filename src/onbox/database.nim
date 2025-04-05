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
# database.nim:
## Some small functions for working with the database. (Open connections, fetch env info and so on.)
## 
## Keep in mind, you will still need to import the actual database logic from the db/ folder

# From somewhere in the standard library
import std/os

# Third party libraries
import iniplus

## In the past, we used an archaic and sorta messed up system for making
## the tables, these have been replaced with a plain old SQL script that gets read
## at compile-time.
##
## Unlike Pleroma, Onbox's config is entirely stored in the config file.
## There is no way to configure Onbox from the database alone.
## So we do not need a tool to generate SQL for a specific instance.

proc getDbHost*(config: ConfigTable): string =
  if existsEnv("ONBOX_DBHOST"):
    return getEnv("ONBOX_DBHOST")
  return config.getStringOrDefault("db", "host", "127.0.0.1:5432")

proc getDbName*(config: ConfigTable): string =
  if existsEnv("ONBOX_DBNAME"):
    return getEnv("ONBOX_DBNAME")
  return config.getStringOrDefault("db", "name", "onbox")

proc getDbUser*(config: ConfigTable): string =
  if existsEnv("ONBOX_DBUSER"):
    return getEnv("ONBOX_DBUSER")
  return config.getStringOrDefault("db", "user", "onbox")

proc getDbPass*(config: ConfigTable): string =
  if existsEnv("ONBOX_DBPASS"):
    return getEnv("ONBOX_DBPASS")
  return config.getString("db", "password")
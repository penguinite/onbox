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
## Some small functions for working with the database. (Fetch env vars, or data from the config in one go.)
## 
## Keep in mind, you will still need to import quark/[WHATEVER FEATURES YOU WANT HERE]

# From somewhere in Pothole
import conf

# From somewhere in the standard library
import std/os

import waterpark/postgres
export postgres

proc hasDbHost*(config: ConfigTable): bool =
  if config.exists("db","host") or existsEnv("PHDB_HOST"):
    return true
  return false

proc getDbHost*(config: ConfigTable): string =
  ## This procedure returns a string containing the name of the database we want to use.
  ## It has a default value of "127.0.0.1:5432" but overrides it based on the config or environment variables (In that order)
  result = config.getStringOrDefault("db","host","127.0.0.1:5432")
  if existsEnv("PHDB_HOST"):
    result = getEnv("PHDB_HOST")

  return result

proc hasDbName*(config: ConfigTable): bool =
  if config.exists("db","name") or existsEnv("PHDB_NAME"):
    return true
  return false

proc getDbName*(config: ConfigTable): string =
  ## This procedure returns a string containing the name of the database we want to use.
  ## It has a default value of "pothole" but overrides it based on the config or environment variables (In that order)
  result = config.getStringOrDefault("db","name","pothole")
  if existsEnv("PHDB_NAME"):
    result = getEnv("PHDB_NAME")
  
  return result

proc hasDbUser*(config: ConfigTable): bool =
  if config.exists("db","user") or existsEnv("PHDB_USER"):
    return true
  return false

proc getDbUser*(config: ConfigTable): string =
  ## This procedure returns a string containing the name of the database we want to use.
  ## It has a default value of "pothole" but overrides it based on the config or environment variables (In that order)
  result = config.getStringOrDefault("db","user","pothole")
  if existsEnv("PHDB_USER"):
    result = getEnv("PHDB_USER")
  
  return result

proc hasDbPass*(config: ConfigTable): bool =
  if config.exists("db","password") or existsEnv("PHDB_PASS"):
    return true
  return false

proc getDbPass*(config: ConfigTable): string =
  ## This procedure returns a string containing the name of the database we want to use.
  ## It has no default value but overrides it based on the config or environment variables (In that order)
  ## 
  result = config.getStringOrDefault("db","password","")
  if existsEnv("PHDB_PASS"):
    result = getEnv("PHDB_PASS")
  return result
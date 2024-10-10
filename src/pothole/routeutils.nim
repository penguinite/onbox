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

# From Quark
import quark/users

# From somewhere in Pothole
import pothole/private/[jsonhelpers, reqhelpers, resphelpers]
import pothole/[database, conf, lib, assets]

# From the standard library
import std/mimetypes
from std/strutils import parseInt, `%`

# From elsewhere
import waterpark, waterpark/postgres

# Export everything
export jsonhelpers, reqhelpers, resphelpers, waterpark, postgres

type
  TemplatingPool* = object
    pool: Pool[TemplateObj]


proc prepareTable*(config: ConfigTable, db: DbConn): Table[string, string] = 
  result = {
    "name": config.getString("instance","name"), # Instance name
    "description": config.getString("instance","description"), # Instance description
    "sign_in": config.getStringOrDefault("web","signin_link", "/auth/sign_in/"), # Sign in link
    "sign_up": config.getStringOrDefault("web","signup_link", "/auth/sign_up/"), # Sign up link
    "log_out": config.getStringOrDefault("web", "logout_link", "/auth/logout/"), # Log out link
    "source": lib.phSourceUrl,
    "signup_enabled": $(config.getBoolOrDefault("user", "registrations_open", true)),
    "version": ""
  }.toTable

  # Instance staff (Any user with the admin attribute)
  if config.exists("web","show_staff") and config.getBool("web","show_staff") == true:
    # Build a list of admins, by using data from the database.
    result["staff"] = ""
    for user in db.getAdmins():
      # Add every admin as a list item.
      result["staff"].add(
        "<li><a href=\"/users/$#\">$#</a></li>" % [user, user]
      )

  # Instance rules (From config)
  if config.exists("instance","rules"):
    # Build the list, item by item using data from the config file.
    result["rules"] = ""
    for rule in config.getStringArray("instance","rules"):
      result["rules"].add("<li>" & rule & "</li>")

  # Pothole version
  if config.getBoolOrDefault("web","show_version", true):
    result["version"] = lib.phVersion
  return result

proc prepareTemplateObj*(db: DbConn, config: ConfigTable): TemplateObj =
  ## Creates a templateObj filled with all the templating stuff we need.
  result.staticFolder = initStatic(config)
  result.templatesFolder = initTemplates(config)
  result.table = prepareTable(config, db)
  result.realURL = config.getString("instance", "uri") & config.getStringOrDefault("web", "endpoint", "/")

proc borrow*(pool: TemplatingPool): TemplateObj {.inline, raises: [], gcsafe.} =
  pool.pool.borrow()

proc recycle*(pool: TemplatingPool, conn: TemplateObj) {.inline, raises: [], gcsafe.} =
  pool.pool.recycle(conn)

proc newTemplatingPool*(size: int = 10, config: ConfigTable, db: DbConn): TemplatingPool =
  result.pool = newPool[TemplateObj]()
  try:
    for _ in 0 ..< size:
      result.pool.recycle(prepareTemplateObj(db, config))
  except CatchableError as err:
    error "Couldn't initialize template pool: ", err.msg

template withConnection*(pool: TemplatingPool, obj, body) =
  block:
    let obj = pool.borrow()
    try:
      body
    finally:
      pool.recycle(obj)

#! These are shared across routes.nim and api.nim
const mimedb*: MimeDB = newMimetypes()

var
  configPool*: ConfigPool
  dbPool*: PostgresPool
  templatePool*: TemplatingPool

proc initEverythingForRoutes*() =
  configPool = newConfigPool(parseInt(getEnvOrDefault("POTHOLE_CONFIG_SIZE", "75")))
  

  configPool.withConnection config:
    dbPool = newPostgresPool(
      config.getIntOrDefault("db", "pool_size", 10),
      config.getdbHost(),
      config.getdbUser(),
      config.getdbPass(),
      config.getdbName()
    )

    dbPool.withConnection db:
      templatePool = newTemplatingPool(
        config.getIntOrDefault("misc", "templating_pool_size", 75),
        config,
        db
      )

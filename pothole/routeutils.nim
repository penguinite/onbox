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

# From somewhere in Quark
import quark/strextra

# From somewhere in Pothole
import conf, assets, lib, database

# From somewhere in the standard library
import std/[tables, options]

# From nimble/other sources
import prologue, temple

var
  config*{.threadvar.}: ConfigTable 
  templatesFolder*{.threadvar.}: string 
  staticFolder*{.threadvar.}: string 
  connectedToDb*{.threadvar}: bool
  db*{.threadvar.}: DbConn
  templateTable*{.threadvar.}: Table[string, string]

proc prepareTable*(db: DbConn = db, config: ConfigTable = config): Table[string, string] =
  ## Creates a table that can be passed onto temple.templateify with all the data we usually need.
  result = {
    "name": config.getString("instance","name"), # Instance name
    "description": config.getString("instance","description"), # Instance description
    "sign_in": config.getStringOrDefault("web","_signin_link", "/auth/sign_in/"), # Sign in link
    "sign_up": config.getStringOrDefault("web","_signup_link", "/auth/sign_up/"), # Sign up link
  }.toTable

  # Instance staff (Any user with the admin attribute)
  if config.exists("web","show_staff") and config.getBool("web","show_staff") == true:
    # Build a list of admins, by using data from the database.
    result["staff"] = ""
    for user in db.getAdmins():
      result["staff"].add("<li><a href=\"/users/" & user & "\">" & user & "</a></li>") # Add every admin as a list item.

  # Instance rules (From config)
  if config.exists("instance","rules"):
    # Build the list, item by item using data from the config file.
    result["rules"] = ""
    for rule in config.getStringArray("instance","rules"):
      result["rules"].add("<li>" & rule & "</li>")

  # Pothole version
  when not defined(phPrivate):
    if config.getBool("web","show_version"):
      result["version"] = lib.phVersion
  return result

proc preRouteInit*() =
  ## Helper proc that must be ran before every route to make sure all the data we need is there.
  
  # TODO: 
  # Ideally replace some parts of this (such as the config file or database)
  # with a connection pool, we could import waterpark and create custom config pools (You've done this before, look in the contrib folder)

  # Config table
  if config.isNil(): 
    config = setup(getConfigFilename())

  # Static folder location
  if staticFolder == "":
    staticFolder = initStatic(config)

  # Template folder location
  if templatesFolder == "":
    templatesFolder = initTemplates(config)

  # Database connection
  if connectedToDb == false:
    db = init(
      config.getDbName(),
      config.getDbUser(),
      config.getDbHost(),
      config.getDbPass()
    )
    connectedToDb = true

  # Template table
  if templateTable.len() == 0:
    templateTable = prepareTable()


proc renderWithExtras*(fn: string, extras: openArray[(string,string)]): string {.gcsafe.} =
  ## Renders the "fn" template file using the usual template table + any extras provided by the extras parameter
  var table = templateTable
  
  for key, val in extras.items:
    table[key] = val

  {.gcsafe.}:
    return templateify(
      getAsset(templatesFolder, fn),
      table
    )

proc render*(fn: string): string {.gcsafe.} =
  ## Renders the template file provided by "filename"
  ## using the usual template table.
  {.gcsafe.}:
    return templateify(
      getAsset(templatesFolder, fn),
      templateTable
    )

proc renderError*(msg: string, file: string = "error.html"): string =
  ## Helper proc to render a "Error!" webpage.
  ## Replace file with your template file of choice
  {.gcsafe.}:
    return templateify(
        getAsset(templatesFolder, file),
      {"result": msg}.toTable,
    )


proc renderSuccess*(msg: string, file: string = "success.html"): string =
  ## Helper proc to render a "Success!" webpage.
  ## Replace file with your template file of choice
  {.gcsafe.}:
    return templateify(
        getAsset(templatesFolder, file),
      {"result": msg}.toTable,
    )

proc isValidQueryParam*(ctx: Context, param: string): bool =
  ## Check if a query parameter (such as "?query=parameter") is valid and not empty
  let param = ctx.getQueryParamsOption(param)
  if isNone(param):
    return false
  if isEmptyOrWhitespace(param.get()):
    return false
  return true

proc isValidFormParam*(ctx: Context, param: string): bool =
  ## Checks if a parameter submitted via an HTMl form is valid and not empty
  let param = ctx.getFormParamsOption(param)
  if isNone(param):
    return false
  if isEmptyOrWhitespace(param.get()):
    return false
  return true

proc getFormParam*(ctx: Context, param: string): string =
  ## Returns a parameter submitted via a HTML form
  return ctx.getFormParamsOption(param).get()

proc isValidPathParam*(ctx: Context, param:string): bool =
  ## Checks if a path parameter such as /users/{user} is valid and not empty
  let param = ctx.getPathParamsOption(param)
  if isNone(param):
    return false
  if isEmptyOrWhitespace(param.get()):
    return false
  return true

proc getPathParam*(ctx: Context, param:string): string =
  ## Returns a path parameter such as /users/{user}
  return ctx.getPathParamsOption(param).get()
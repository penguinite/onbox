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
import pothole/[conf, database, lib, assets]

# From somewhere in the standard library
import std/[tables, options, mimetypes, macros, json]
from std/strutils import `%`

# From nimble/other sources
import mummy, mummy/multipart, waterpark, waterpark/postgres, temple

# Oh dear god... A "Template Object" pool.
# TODO: It's obvious why *this* needs refactoring, so in the future, please do that.
type
  TemplateObj* = object
    staticFolder*: string
    templatesFolder*: string
    table*: Table[string, string]

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

proc render*(obj: TemplateObj, fn: string, extras: openArray[(string,string)] = @[]): string =
  ## Renders the "fn" template file using the usual template table + any extras provided by the extras parameter
  var table = obj.table

  for key, val in extras.items:
    table[key] = val

  return templateify(
    getAsset(obj.templatesFolder, fn),
    table
  )

proc renderError*(obj: TemplateObj, msg: string, fn: string = "generic.html"): string =
  return obj.render(
    fn,
    {
      "message_type": "error",
      "title": "Error!",
      "message": msg
    }
  )


proc renderSuccess*(obj: TemplateObj, msg: string, fn: string = "generic.html"): string =
  return obj.render(
    fn,
    {
      "message_type": "success",
      "title": "Success!",
      "message": msg
    }
  )

proc hasSessionCookie*(req: Request): bool =
  if not req.headers.contains("Cookie"):
    return false

  var
    val = ""
    flag = false
  for item in req.headers["Cookie"].smartSplit('='):
    if flag:
      val = item
      flag = false
    if item == "session":
      flag = true
  
  if val.isEmptyOrWhitespace() and val != "null":
    return false
  return true

proc fetchSessionCookie*(req: Request): string = 
  var flag = false
  for val in req.headers["Cookie"].smartSplit('='):
    if flag:
      return val
    if val == "session":  
      flag = true

proc createHeaders*(a: string): HttpHeaders =
  result["Content-Type"] = a
  return

macro respJsonError*(msg: string, code = 400, headers = createHeaders("application/json")) =
  var req = ident"req"

  result = quote do:
    `req`.respond(
      `code`, `headers`, $(%*{"error": `msg`})
    )
    return

macro respJson*(msg: JsonNode, code = 200, headers = createHeaders("application/json")) =
  var req = ident"req"

  result = quote do:
    `req`.respond(
      `code`, `headers`, $(msg)
    )
    return

proc isValidQueryParam*(req: Request, query: string): bool =
  ## Check if a query parameter (such as "?query=parameter") is valid and not empty
  return not req.queryParams[query].isEmptyOrWhitespace()

proc getQueryParam*(req: Request, query: string): string =
  ## Returns a query parameter (such as "?query=parameter")
  return req.queryParams[query]

proc isValidPathParam*(req: Request, path: string): bool =
  ## Checks if a path parameter such as /users/{user} is valid and not empty
  return not req.pathParams[path].isEmptyOrWhitespace()

proc getPathParam*(req: Request, path: string): string =
  ## Returns a path parameter such as /users/{user}
  return req.pathParams[path]

type
  MultipartEntries* = Table[string, string]
  FormEntries* = Table[string, string]

proc unrollMultipart*(req: Request): MultipartEntries =
  ## Unrolls a Mummy multipart data thing into a table of strings.
  ## which is way easier to handle.
  ## TODO: Maybe reconsider this approach? The example file mentions a way to do this *without* copying.
  for entry in req.decodeMultipart():
    if entry.data.isNone():
      continue
    
    let
      (start, last) = entry.data.get()
      val = req.body[start .. last]

    if val.isEmptyOrWhitespace():
      continue

    result[entry.name] = val
  return result

proc isValidMultipartParam*(mp: MultipartEntries, param: string): bool =
  ## Returns a parameter submitted via a HTML form
  return mp.hasKey(param) and not mp[param].isEmptyOrWhitespace()

proc getMultipartParam*(mp: MultipartEntries, param: string): string =
  ## Checks if a parameter submitted via an HTMl form is valid and not empty
  return mp[param]

proc unrollForm*(req: Request): FormEntries =
  let entries = req.body.smartSplit('&')

  for entry in entries:
    if '=' notin entry:
      continue # Invalid entry: Does not have equal sign.

    let entrySplit = entry.smartSplit('=') # let's just re-use this amazing function.

    if len(entrySplit) != 2:
      continue # Invalid entry: Does not have precisely two parts.

    var
      key = entrySplit[0].decodeQueryComponent()
      val = entrySplit[1].decodeQueryComponent()

    if key.isEmptyOrWhitespace() or val.isEmptyOrWhitespace():
      continue # Invalid entry: Key or val (or both) are empty or whitespace. Invalid.

    result[key] = val
  
  return result

proc isValidFormParam*(mp: FormEntries, param: string): bool =
  ## Returns a parameter submitted via a HTML form
  return mp.hasKey(param) and not mp[param].isEmptyOrWhitespace()

proc getFormParam*(mp: FormEntries, param: string): string =
  ## Checks if a parameter submitted via an HTMl form is valid and not empty
  return mp[param]


#! These are shared across routes.nim and api.nim
const mimedb*: MimeDB = newMimetypes()

var
  configPool*: ConfigPool
  dbPool*: PostgresPool
  templatePool*: TemplatingPool

proc initEverythingForRoutes*() =
  configPool = newConfigPool()
  

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

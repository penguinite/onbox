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

# From somewhere in Onbox
import onbox/[conf, strextra], onbox/db/[oauth, users]

# From the standard library
import std/[mimetypes, os, macros, tables, json, strutils]

# From elsewhere
import waterpark/postgres, mummy, mummy/multipart, iniplus

const mimedb*: MimeDB = newMimetypes()

var
  configPool*: ConfigPool
  dbPool*: PostgresPool

type
  MultipartEntries* = Table[string, string]
  FormEntries* = Table[string, string]

proc realURL*(config: ConfigTable): string =
  return config.getString("instance", "uri") & config.getStringOrDefault("web", "endpoint", "/")

proc createHeaders*(a: string): HttpHeaders = result["Content-Type"] = a
macro respJsonError*(msg: string, code = 400, headers = createHeaders("application/json")) =
  var req = ident"req"
  result = quote do:
    `req`.respond(
      `code`, `headers`, $(%*{"error": `msg`})
    )
    return

macro respJson*(msg: string, code = 200, headers = createHeaders("application/json")) =
  var req = ident"req"
  result = quote do:
    `req`.respond(
      `code`, `headers`, `msg`
    )
    return

proc queryParamExists*(req: Request, query: string): bool =
  ## Check if a query parameter (such as "?query=parameter") is valid and not empty
  return not req.queryParams[query].isEmptyOrWhitespace()

proc pathParamExists*(req: Request, path: string): bool =
  ## Checks if a path parameter such as /users/{user} is valid and not empty
  return not req.pathParams[path].isEmptyOrWhitespace()

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

proc multipartParamExists*(mp: MultipartEntries, param: string): bool =
  ## Returns a parameter submitted via a HTML form
  return mp.hasKey(param) and not mp[param].isEmptyOrWhitespace()

proc unrollForm*(req: Request): FormEntries =
  # TODO: This works well for simple key=val form data
  # But it won't work for arrays like: array[]=item_1&array[]=item_2
  # Nor will it work for tables (What mastodon calls "Nested parameters")
  # Such as: source[privacy]=public&source[language]=en
  #
  # It would be easiest to make a Form Data to JsonNode converter proc
  # So that we can re-use our JSON input logic, thus making everything
  # nicer to maintain.
  #
  # See: https://docs.joinmastodon.org/client/intro/#form-data
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

proc formParamExists*(fe: FormEntries, param: string): bool =
  ## Returns a parameter submitted via a HTML form
  return fe.hasKey(param) and not fe[param].isEmptyOrWhitespace()

proc fetchSessionCookie*(req: Request): string = 
  ## Fetches the session cookie (if it exists) from a request.
  var flag = false
  for x in req.headers["Cookie"].smartSplit('='):
    if flag: return x
    if x == "session": flag = true

proc hasSessionCookie*(req: Request): bool =
  ## Checks if the request has a Session cookie for authorization.
  
  # The cookie header might contain other cookies.
  # So we need to parse this header.
  # The header looks like so: Name=Value; Name=Value
  if not req.headers.contains("Cookie"):
    return false
  return not fetchSessionCookie(req).isEmptyOrWhitespace()

proc hasValidStrKey*(j: JsonNode, k: string): bool =
  ## Checks if a key in a json node object is a valid string.
  ## It primarily checks for existence, kind, and emptyness.
  try: return j.hasKey(k) and j[k].kind == JString and not j[k].getStr().isEmptyOrWhitespace()
  except: return false

proc getContentType*(req: Request): string =
  ## Returns the content-type of a request.
  ## 
  ## This also does some extra checks for if the content-type
  ## has other info (like MIME boundary info) and strips it out
  result = "application/x-www-form-urlencoded"
  if req.headers.contains("Content-Type"):
    result = req.headers["Content-Type"]
  
  # Some clients such as tuba send their content-type as
  # multipart/form-data; boundary=...
  # And so, we will return everything before
  # the first semicolon 
  if ';' in result:
    result = result.split(';')[0]

proc authHeaderExists*(req: Request): bool =
  ## Checks if the auth header exists, which is required for some API routes.
  return req.headers.contains("Authorization") and not isEmptyOrWhitespace(req.headers["Authorization"])

proc getAuthHeader*(req: Request): string =
  ## Gets the auth from a request header if it exists
  result = req.headers["Authorization"].strip()
  if result.startsWith("Bearer "):
    result = result[7..^1]

proc verifyClientExists*(req: Request): string =
  ## Verifies that the API client is calling with a token that exists in the database.
  ## Returns the token provided by the client for convenience.
  runnableExamples:
    try:
      req.verifyClientExists()
    except: return

  if not req.authHeaderExists():
    req.respond(400, createHeaders("application/json"), "{\"error\": \"Client hasn't provided an auth header\"}")
    raise newException(CatchableError, "")

  result = req.getAuthHeader()

  dbPool.withConnection db:
    if not db.tokenExists(result):
      req.respond(401, createHeaders("application/json"), "{\"error\": \"Client's auth header is invalid\"}")
      raise newException(CatchableError, "")

proc verifyClientScope*(req: Request, token, scope: string) =
  ## Verifies that the client calling this has a scope.
  runnableExamples:
    var token = ""
    try:
      token = req.verifyClientExists()
      req.verifyClientScope(token, "read:account")
    except: return

  dbPool.withConnection db:
    if not db.tokenHasScope(token, "read"):
      req.respond(401, createHeaders("application/json"), "{\"error\": \"Insufficient permissions on token.\"}")
      raise newException(CatchableError, "")

proc verifyClientUser*(req: Request, token: string): string =
  ## Verifies that the client calling this has a user connected.
  ## Returns the user ID for convenience
  runnableExamples:
    var token, user = ""
    try:
      token = req.verifyClientExists()
      req.verifyClientScope(token, "read:account")
      user = req.verifyClientUser(token)
    except: return
  
  dbPool.withConnection db:
    result = db.getTokenUser(token)
    if result == "":
      req.respond(401, createHeaders("application/json"), "{\"error\": \"No user associated with token\"}")
      raise newException(CatchableError, "")
  
    # Frozen/Suspension check
    if db.userHasRole(result, -1):
      req.respond(403, createHeaders("application/json"), "{\"error\": \"Your login is currently disabled\"}")
      raise newException(CatchableError, "")
    
    # Check if the user's email has been verified.
    # But only if user.require_verification is true
    configPool.withConnection config:
      if config.getBoolOrDefault("user", "require_verification", false) and not db.userVerified(result):
        req.respond(403, createHeaders("application/json"), "{\"error\": \"Your login is missing a confirmed e-mail address\"}")
        raise newException(CatchableError, "")
    
    # Check if the user's account is pending verification
    if not db.userHasRole(result, 1):
      req.respond(403, createHeaders("application/json"), "{\"error\": \"Your login is currently pending approval\"}")
      raise newException(CatchableError, "")
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

# From potholepkg or pothole's server codebase
import lib,conf,database,assets,user,crypto

# From stdlib
import std/[tables, options]
import std/strutils except isEmptyOrWhitespace, parseBool

# From nimble/other sources
import prologue

var
  config {.threadvar.} = setup(getConfigFilename())
  staticFolder {.threadvar.} = initStatic(config)
  db {.threadvar.} = init(config)
  templateTable: Table[string, string] = {
    "version":"", # Pothole version
    "staff": "<p>None</p>", # Instance staff (Any user with the admin attribute)
    "rules": "<p>None</p>", # Instance rules (From config)
    "result": "", # This is used for embedding errors within pages. It should always be empty.
    "name": config.getString("instance","name"), # Instance name
    "description": config.getString("instance","description") # Instance description
  }.toTable

if config.exists("web","show_staff") and config.getBool("web","show_staff") == true:
  templateTable["staff"] = "" # Clear whatever is already in this.
  # Build a list of admins, by using data from the database.
  templateTable["staff"].add("<ul>")
  for user in db.getAdmins():
    templateTable["staff"].add("<li><a href=\"/@" & user & "\">" & user & "</a></li>") # Add every admin as a list item.
  templateTable["staff"].add("</ul>")

if config.exists("instance","rules"):
  templateTable["rules"] = "" # Again, clear whatever is in it first.
  # Build the list, item by item using data from the config file.
  templateTable["rules"].add("<ol>")
  for rule in config.getStringArray("instance","rules"):
    templateTable["rules"].add("<li>" & rule & "</li>")
  templateTable["rules"].add("</ol>")

when not defined(phPrivate):
  if config.getBool("web","show_version"):
    templateTable["version"] = lib.phVersion

proc preRouteInit() =
  if config.isNil(): config = setup(getConfigFilename())
  if staticFolder == "": staticFolder = initStatic(config)
  db = init(config) # TODO: Fix database.isNil()

proc renderWithFullTable(fn: string, extras: openArray[(string,string)]): string {.gcsafe.} =
  {.gcsafe.}:
    var table = templateTable
  
  for key, val in extras.items:
    table[key] = val

  {.gcsafe.}:
    return renderTemplate(
      getAsset(staticFolder, fn),
      table
    )

proc renderWithFullTable(fn: string): string {.gcsafe.} =
  {.gcsafe.}:
    return renderTemplate(
      getAsset(staticFolder, fn),
      templateTable
    )
  
macro response(body: string, code = Http200, version = HttpVer11) = 
  # A copy paste of prologue's `resp` macro with one extra addition.
  # A return statement so that the rest of the code doesn't get executed when we don't want it to.
  var ctx = ident"ctx"
  result = quote do:
    `ctx`.response.httpVersion = `version`
    `ctx`.response.code = `code`
    `ctx`.response.body = `body`
    return

proc renderError(error: string): string =
  # One liner to generate an error webpage.
  {.gcsafe.}:
    return renderTemplate(
        getAsset(staticFolder,"error.html"),
      {"error": error}.toTable,
    )

proc renderError(error, fn: string): string =
  {.gcsafe.}:
    var table = templateTable
    table["result"] = "<div class=\"error\"><p>" & error & "</p></div>"
    return renderTemplate(
        getAsset(staticFolder, fn),
      table
    )

proc renderSuccess(str: string): string =
  # One liner to generate a "Success!" webpage.
  {.gcsafe.}:
    return renderTemplate(
        getAsset(staticFolder, "success.html"),
      {"result": str}.toTable,
    )

proc renderSuccess(msg, fn: string): string =
  {.gcsafe.}:
    var table = templateTable
    table["result"] = "<div class=\"success\"><p>" & msg & "</p></div>"
    return renderTemplate(
      getAsset(staticFolder, fn),
      table
    )

proc isValidQueryParam(ctx: Context, param: string): bool {.async.} =
  let param = ctx.getQueryParamsOption(param)
  if isNone(param):
    return false
  if isEmptyOrWhitespace(param.get())
    return false
  return true

proc isValidFormParam(ctx: Context, param: string): bool {.async.} =
  let param = ctx.getFormParamsOption(param)
  if isNone(param):
    return false
  if isEmptyOrWhitespace(param.get())
    return false
  return true

proc getFormParam(ctx: Context, param: string): string {.async.} =
  return ctx.getFormParamsOption(param).get()

#! Actual prologue routes

# our serveStatic route reads from static/FILENAME and renders it as a template.
# This helps keep everything simpler, since we just add our route to the string, it's asset and
# Bingo! We've got a proper route that also does templating!

# But this won't work for /auth/ routes!

const staticURLs*: Table[string,string] = {
  "/": "index.html", 
  "/about": "about.html", "/about/more": "about.html", # About pages, they run off of the same template.
}.toTable


proc serveStatic*(ctx: Context) {.async.} =
  var path = ctx.request.path

  # If the path has a slash at the end, remove it.
  # Except if the path is the root, aka. literally just a slash
  if path.endsWith("/") and path != "/": path = path[0..^2]

  respond renderWithFullTable(staticURLs[path])

proc serveCSS*(ctx: Context) {.async.} = 
  ctx.response.addHeader("Content-Type", "text/css")
  respond getAsset(staticFolder, "style.css")

proc get_auth_signup*(ctx: Context) {.async.} =
  var filename = "signup.html"

  if config.exists("user","registrations_open") and config.getBool("user","registrations_open") == false:
    filename = "signup_disabled.html"

  respond renderWithFullTable(filename)

proc post_auth_signup*(ctx: Context) =
  # First... As an absolute must.
  # Check if the registrations are open.
  # I don't know how I missed this obvious flaw
  # the first time I wrote this route.
  if config.exists("user","registrations_open") and config.getBool("user","registrations_open") == false:
    respond renderError("This instance has disabled user registrations.", "signup_disabled.html")
  
  # Let's first check for required options.
  # Everything else will come later.
  if not ctx.isValidFormParam("user"):
    respond renderError("Missing or invalid username.","signup.html")

  if not ctx.isValidFormParam("pass"):
    respond renderError("Missing or invalid password.","signup.html")

  # Then let's check if the username exists.
  if db.userHandleExists(ctx.getFormParam("user")):
    respond renderError("Another user with the same handle already exists","signup.html")
  
  var email = ""
  when not defined(phPrivate):
    if not ctx.isValidFormParam("email"):
      respond renderError("Missing or invalid email.","signup.html")
  else:
    if ctx.isValidFormParam("email"):
      email = ctx.getFormParam("email")

  var user = newUser(ctx.getFormParam("user"), true, ctx.getFormParam("pass"))
  user.email = email

  # Set bio
  user.bio = ""
  if ctx.isValidFormParam("bio"):
    user.bio = ctx.getFormParam("bio")

  # Set display name
  user.name = user.handle
  if ctx.isValidFormParam("name"):
    user.name = ctx.getFormParam("name")
  
  # Make user non-approved if instance requires approval for registration.
  {.gcsafe.}:
    if config.getBool("user","require_approval"):
      user.is_approved = false # User isn't allowed to login until their account is approved.

    if db.addUser(user):
      req.htmlResponse renderSuccess("Your account has been successfully registered. " & crypto.randomString(),"signup.html")
    else:
      req.htmlResponse renderError("Account registration failed! Ask for help from administrator!","signup.html")

proc get_auth_signin*(ctx: Context) =
  {.gcsafe.}:
    req.htmlResponse renderTemplate(
        getAsset(staticFolder, "signin.html"),
        templateTable
    )

proc post_auth_signin*(ctx: Context) =
  let data = req.decodeMultipartEx()
  
  # Let's first check for required options.
  # Everything else will come later.
  if not data.hasKey("user"):
    req.htmlResponse renderError("Missing or invalid username.","signin.html")

  if not data.hasKey("pass"):
    req.htmlResponse renderError("Missing or invalid password.","signin.html")

  # Check if user exists
  var user: User
  {.gcsafe.}:
    if not db.userHandleExists(sanitizeHandle(data["user"])):
      req.htmlResponse renderError("User does not exist.","signin.html")

    user = db.getUserByHandle(sanitizeHandle(data["user"]))

  # Disable login if account is frozen or not yet approved.
  if user.is_frozen: req.htmlResponse renderError("Your account has been frozen, contact the administrators of this instance.","signin.html")
  {.gcsafe.}:
    if not user.is_approved and config.getBool("user","require_approval") == true:
      req.htmlResponse renderError("Your account has not been approved yet. Contact the administrators of this instance.","signin.html")
  

  # TODO: Implement this once postgres is stable
  # Session tokens will be stored in a separate table.
  # consisting of the following schema:
  # "user": BLOB NOT NULL, # Id of token's user.
  # "token": "BLOB NOT NULL", # The actual token itself.
  # "written": "TIMESTAMP NOT NULL", # Timestamp of when the token was last used. If it hasn't been used in more than two weeks then kill it with fire.
  # "ip": "BLOB NOT NULL" # A hash of the user's IP address. On phPrivate, this is not used whatsoever.
  # "salt": "BLOB UNIQUE NOT NULL" # A small salt used to hash the user's IP address
  
  req.htmlResponse renderError("Login is not implemented yet... Sorry! ;( But here is some debugging ifno: " & $user,"signin.html")
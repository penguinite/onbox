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
import lib,conf,database,assets,user,post,crypto

# From stdlib
import std/[tables, options]
import std/strutils except isEmptyOrWhitespace, parseBool

# From nimble/other sources
import mummy, mummy/[routers, multipart]


{.gcsafe.}:
  let
    config: ConfigTable = setup(getConfigFilename())
    staticFolder: string = initStatic(config)
    db: database.DbConn = init(config)

proc preRouteInit() =
  discard

proc prepareTable(config: ConfigTable, db: DbConn): Table[string,string] =
  var table = { # Config table for the templating library.
    "name":config.getString("instance","name"), # Instance name
    "description":config.getString("instance","description"), # Instance description
    "version":"", # Pothole version
    "staff": "<p>None</p>", # Instance staff (Any user with the admin attribute)
    "rules": "<p>None</p>", # Instance rules (From config)
    "result": "" # This is used for embedding errors within pages. It should always be empty.
  }.toTable

   # Add admins and other staff
  if config.getBool("web","show_staff"):
    
    table["staff"] = "" # Clear whatever is in it first.
    # Build the list, item by item using database functions.
    table["staff"].add("<ul>")
    for user in db.getAdmins():
      table["staff"].add("<li><a href=\"/@" & user & "\">" & user & "</a></li>") # Add every admin as a list item.
    table["staff"].add("</ul>")

   # Add instance rules
  if config.exists("instance","rules"):
    table["rules"] = "" # Again, clear whatever is in it first.
    # Build the list, item by item using data from the config file.
    table["rules"].add("<ol>")
    for rule in config.getStringArray("instance","rules"):
      table["rules"].add("<li>" & rule & "</li>")
    table["rules"].add("</ol>")

  when not defined(phPrivate):
    if config.getBool("web","show_version"):
      table["version"] = lib.phVersion

  return table

proc renderError(error: string): string =
  # One liner to generate an error webpage.
  return renderTemplate(
    getAsset(staticFolder,"error.html"),
    {"error": error}.toTable,
  )

proc renderError(error, fn: string): string =
  var table = prepareTable(config, db)
  table["result"] = "<div class=\"error\"><p>" & error & "</p></div>"
  return renderTemplate(
    getAsset(staticFolder, fn),
    table
  )

proc renderSuccess(str: string): string =
  # One liner to generate a "Success!" webpage.
  return renderTemplate(
    getAsset(staticFolder, "success.html"),
    {"result": str}.toTable,
  )

proc renderSuccess(msg, fn: string): string =
  var table = prepareTable(config, db)
  table["result"] = "<div class=\"success\"><p>" & msg & "</p></div>"
  return renderTemplate(
    getAsset(staticFolder, fn),
    table
  )

proc isValidQueryParam(req: Request, param: string): bool =
  if isEmptyOrWhitespace(req.queryParams[param]):
    return false
  return true

proc decodeMultipartEx(req: Request): Table[string, string] {.raises: [MummyError].} =
  ## Mummy's built-in Multipart handling is stupid and difficult to use.
  ## So this procedure takes a Mummy request object and transforms it into a lovely Table[string, string]
  ## Note: Empty or whitespace-only data (Anything that will be thrown out by lib.isEmptyOrWhitespace) will not be added into the table.
  ## TODO: Maybe investigate what entry.filename is supposed to be? We throw that away as of now.
  let entries = req.decodeMultipart()
  for entry in entries:
    if isEmptyOrWhitespace(entry.name):
      continue # Skip if entry name is mostly empty
    if isNone(entry.data):
      continue # Skip if entry data isn't provided
    let
      (start, last) = entry.data.get
      data = req.body[start .. last]

    if isEmptyOrWhitespace(data):
      continue
    
    result[entry.name] = data
  return result

template htmlResponse(req: Request, html: string) =
  ## Quick template that initializes headers with text/html content type and responds with a 200 code.
  ## Very useful for cutting down on unneeded code.
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  req.respond(200, headers, html)

#! Actual prologue routes

# our serveStatic route reads from static/FILENAME and renders it as a template.
# This helps keep everything simpler, since we just add our route to the string, it's asset and
# Bingo! We've got a proper route that also does templating!

# But this won't work for /auth/ routes!

const staticURLs*: Table[string,string] = {
  "/": "index.html", 
  "/about": "about.html", "/about/more": "about.html", # About pages, they run off of the same template.
}.toTable


proc serveStatic*(req: Request) =
  preRouteInit()
  var path = req.path

  # If the path has a slash at the end, remove it.
  # Except if the path is the root, aka. literally just a slash
  if path.endsWith("/") and path != "/": path = path[0..^2]

  req.htmlResponse(
    renderTemplate(
      getAsset(staticFolder, staticURLs[path]),
      prepareTable(config, db)
    )
  )

proc serveCSS*(req: Request) = 
  preRouteInit()
  var headers: HttpHeaders
  headers["Content-Type"] = "text/css"
  req.respond(200, headers, getAsset(staticFolder, "style.css"))

proc get_auth_signup*(req: Request) =
  preRouteInit()
  var filename = "signup.html"

  if config.exists("user","registrations_open") and config.getBool("user","registrations_open") == false:
    filename = "signup_disabled.html"

  req.htmlResponse(renderTemplate(
    getAsset(staticFolder, filename),
    prepareTable(config, db)
  ))

proc post_auth_signup*(req: Request) =
  preRouteInit()

  # First... As an absolute must.
  # Check if the registrations are open.
  # I don't know how I missed this obvious flaw
  # the first time I wrote this route.
  if config.exists("user","registrations_open") and config.getBool("user","registrations_open") == false:
    req.htmlResponse renderError("This instance has disabled user registrations.")
  
  let multiData = req.decodeMultipartEx()

  # Let's first check for required options.
  # Everything else will come later.
  if not multiData.hasKey("user"):
    req.htmlResponse renderError("Missing or invalid username.","signup.html")

  if not multiData.hasKey("pass"):
    req.htmlResponse renderError("Missing or invalid password.","signup.html")

  # Then let's check if the username exists.
  if db.userHandleExists(multiData["user"]):
    req.htmlResponse renderError("Another user with the same handle already exists","signup.html")
  
  var email = ""
  when not defined(phPrivate):
    if not multiData.hasKey("email"):
      req.htmlResponse renderError("Missing or invalid email.","signup.html")
  else:
    if multiData.hasKey("email"):
      email = multiData["email"]

  var user = newUser(multiData["user"], true, multiData["pass"])
  user.email = email

  # Set bio
  user.bio = ""
  if multiData.hasKey("bio"):
    user.bio = multiData["bio"]

  # Set display name
  user.name = sanitizeHandle(multiData["user"])
  if multiData.hasKey("name"):
    user.bio = multiData["name"]
  
  # Make user non-approved if instance requires approval for registration.
  if config.getBool("user","require_approval"):
    user.is_approved = false # User isn't allowed to login until their account is approved.

  if db.addUser(user):
    req.htmlResponse renderSuccess("Your account has been successfully registered. " & crypto.randomString(),"signup.html")
  else:
    req.htmlResponse renderError("Account registration failed! Ask for help from administrator!","signup.html")

proc get_auth_signin*(req: Request) =
  preRouteInit()

  req.htmlResponse renderTemplate(
    getAsset(staticFolder, "signin.html"),
    prepareTable(config, db)
  )

proc post_auth_signin*(req: Request) =
  preRouteInit()
  let data = req.decodeMultipartEx()
  
  # Let's first check for required options.
  # Everything else will come later.
  if not data.hasKey("user"):
    req.htmlResponse renderError("Missing or invalid username.","signin.html")

  if not data.hasKey("pass"):
    req.htmlResponse renderError("Missing or invalid password.","signin.html")

  # Check if user exists
  if not db.userHandleExists(sanitizeHandle(data["user"])):
    req.htmlResponse renderError("User does not exist.","signin.html")

  let user = db.getUserByHandle(sanitizeHandle(data["user"]))

  # Disable login if account is frozen or not yet approved.
  if user.is_frozen: req.htmlResponse renderError("Your account has been frozen, contact the administrators of this instance.","signin.html")
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


proc randomPosts*(req: Request) =
  preRouteInit()
  var response = """<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" coctx.getPostParamsOption("username").get()ntent="width=device-width, initial-scale=1"><title>Showing local posts</title><link rel="stylesheet" href="/css/style.css"/></head><body>"""
  for post in db.getLocalPosts(0):
    response.add("<article>")
    response.add("<p>From " & post.sender & "<br>")
    if len(post.recipients) < 1:
      for person in post.recipients:
        response.add("To: " & person & "</p>")
    else:
      response.add("To: Everyone!</p>")
    response.add("<p>" & post.content & "</p>")
    if post.local:
      response.add("<p>Local post, Written: " & formatDate(post.written) & "</p>")
    else:
      response.add("<p>Written: " & formatDate(post.written) & "</p>")

    response.add("<ul>")
    for reaction, list in post.reactions:
      response.add("<li>")
      for reactor in list:
        response.add(reactor & ", ")
      response = response[0..^3]
      response.add("reacted with " & reaction & "</li>")
    response.add("</ul>")
    #if len(post.boosts) > 0:
    #  response.add("<ul>")
    #  for boost in post.boosts:
    #    response.add("<li>" & boost.actor & " boosted")
    #    case boost.action:
    #    of "all":
    #      response.add(" to everyone!")
    #    of "followers":
    #      response.add(" to their followers!")
    #    of "local":
    #      response.add(" to their instance!")
    #    of "private":
    #      response.add(" to themselves!")
    #    response.add("</li>")
    #  response.add("</ul>")
    response.add("</article><hr>")
  response.add("</body></html>")
  req.htmlResponse(response)
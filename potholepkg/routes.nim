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
import std/strutils except isEmptyOrWhitespace

# From nimble/other sources
import prologue

var
  config {.threadvar.}: Table[string, string]
  staticFolder {.threadvar.}: string
  db {.threadvar.}: DbConn

proc preRouteInit() =
  ## This route is ran before every single request.
  ## It has very little overhead yet it ensures that all the data we need is available for every request.
  if config.isNil(): config = setup(getConfigFilename())
  if staticFolder == "": staticFolder = initStatic(config)
  if not db.isOpen(): db = quickInit(config)


#! Actual prologue routes

# our serveStatic route reads from static/FILENAME and renders it as a template.
# This helps keep everything simpler, since we just add our route to the string, it's asset and
# Bingo! We've got a proper route that also does templating!

# But this won't work for /auth/ routes!

const staticURLs*: Table[string,string] = {
  "/": "index.html", 
  "/about": "about.html", "/about/more": "about.html", # About pages, they run off of the same template.
}.toTable

proc prepareTable(config: Table[string, string], db: DbConn): Table[string,string] =
  var table = { # Config table for the templating library.
    "name":config.getString("instance","name"), # Instance name
    "description":config.getString("instance","description"), # Instance description
    "version":"", # Pothole version
    "staff": "<p>None</p>", # Instance staff (Any user with the admin attribute)
    "rules": "<p>None</p>" # Instance rules (From config)
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
    for rule in config.getArray("instance","rules"):
      table["rules"].add("<li>" & rule & "</li>")
    table["rules"].add("</ol>")

  when not defined(phPrivate):
    if config.getBool("web","show_version"):
      table["version"] = lib.phVersion

  return table

proc serveStatic*(ctx: Context) {.async.} =
  preRouteInit()

  var path = ctx.request.path

  if path.endsWith("/") and path != "/": path = path[0..^2]
  # If the path has a slash at the end, remove it.
  # Except if the path is the root, aka. literally just a slash

  resp renderTemplate(
    getAsset(staticFolder, staticURLs[path]),
    prepareTable(config, db)
  )

proc serveCSS*(ctx: Context) {.async.} = 
  preRouteInit()
  ctx.response.setHeader("Content-Type","text/css")
  resp getAsset(staticFolder, "style.css")

proc get_auth_signup*(ctx: Context) {.async.} =
  preRouteInit()
  var filename = "signup.html"

  if config.exists("user","registrations_open") and config.getBool("user","registrations_open") == false:
    filename = "signup_disabled.html"

  resp renderTemplate(
    getAsset(staticFolder, filename),
    prepareTable(config, db)
  )

proc renderError(error: string): string =
  # One liner to generate an error webpage.
  return renderTemplate(
    getAsset(staticFolder,"error.html"),
    {"error": error}.toTable,
  )

proc renderSuccess(str: string): string =
  # One liner to generate a "Success!" webpage.
  return renderTemplate(
    getAsset(staticFolder, "success.html"),
    {"result": str}.toTable,
  )

proc post_auth_signup*(ctx: Context) {.async.} =
  preRouteInit()
  proc isInvalidParam(str: string): bool =
    ## Returns true if the parameter is invalid (It doesnt exist or it's nearly empty)
    let param = ctx.getPostParamsOption(str)
    if isNone(param) or isEmptyOrWhitespace(param.get()):
      return true
    return false

  proc getParam(str: string): string =
    # I just hate writing ctx.getPostParamsOption().get() everywhere
    return ctx.getPostParamsOption(str).get()

  # Let's first check for required options.
  # Everything else will come later.
  if isInvalidParam("user"):
    resp renderError("Missing or invalid username.")

  if isInvalidParam("pass"):
    resp renderError("Missing or invalid password.")

  # Email is a bit special since we have the phPrivate feature.
  var email = ""

  when defined(phPrivate):
    if not isInvalidParam("email"):
      email = getParam("email")
  else:
    if isInvalidParam("email"):
      resp renderError("Missing or invalid email.")
    email = getParam("email")

  var user = newUser(getParam("user"))
  user.local = true # newUser() sets this as false.
  user.password = pbkdf2_hmac_sha512_hash(getParam("pass"),user.salt)
  user.email = email

  user.name = toLowerAscii(user.handle)
  if not isInvalidParam("name"):
    user.name = getParam("name")

proc randomPosts*(ctx:Context) {.async.} =
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
  resp htmlResponse(response)

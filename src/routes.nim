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

# From libpothole or pothole's server codebase
import libpothole/[lib,post,conf,database]
import assets

# From stdlib
import std/tables
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
  ctx.response.setHeader("Content-Type","text/css")
  resp getAsset(staticFolder, "style.css")

when defined(debug):
  proc randomPosts*(ctx:Context) {.async.} =
    preRouteInit()

    var response = """<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Showing local posts</title><link rel="stylesheet" href="/css/style.css"/></head><body>"""
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
      if len(post.favorites) > 0:
        response.add("<ul>")
        for reaction in post.favorites:
          response.add("<li>" & reaction.actor & " reacted with " & reaction.action & "</li>")
        response.add("</ul>")
      if len(post.boosts) > 0:
        response.add("<ul>")
        for boost in post.boosts:
          response.add("<li>" & boost.actor & " boosted")
          case boost.action:
          of "all":
            response.add(" to everyone!")
          of "followers":
            response.add(" to their followers!")
          of "local":
            response.add(" to their instance!")
          of "private":
            response.add(" to themselves!")
          response.add("</li>")
        response.add("</ul>")
      response.add("</article><hr>")

    response.add("</body></html>")

    resp htmlResponse(response)
  
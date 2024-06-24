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
import quark/[user, post]

# From somewhere in Pothole
import conf, assets, database, routeutils

# From somewhere in the standard library
import std/[tables]
import std/strutils except isEmptyOrWhitespace, parseBool

# From nimble/other sources
import prologue, temple

# our serveStatic route reads from static/FILENAME and renders it as a template.
# This helps keep everything simpler, since we just add our route to the string, it's asset and
# Bingo! We've got a proper route that also does templating!

# But this won't work for /auth/ routes!

const renderURLs*: Table[string,string] = {
  "/": "index.html", 
  "/about": "about.html", "/about/more": "about.html", # About pages, they run off of the same template.
}.toTable


proc serveCSS*(ctx: Context) {.async.} = 
  ## This procedure gets ran whenever staticFolder/style.css doesnt exist
  preRouteInit()
  ctx.response.addHeader("Content-Type", "text/css")
  resp getEmbeddedAsset("style.css")

proc serveRenderedAsset*(ctx: Context) {.async.} =
  preRouteInit()
  var path = ctx.request.path

  # If the path has a slash at the end, remove it.
  # Except if the path is the root, aka. literally just a slash
  if path.endsWith("/") and path != "/": path = path[0..^2]

  resp render(renderURLs[path])

proc serveStatic*(ctx: Context) {.async.} = 
  await ctx.staticFileResponse(ctx.request.path, "")

proc get_auth_signup*(ctx: Context) {.async.} =
  preRouteInit()
  resp renderWithExtras(
    "signup.html",
    @[("signup_enabled": $(config.getBoolOrDefault("user","registrations_open",true)))]
  )
  resp render(filename)

proc post_auth_signup*(ctx: Context) {.async.} =
  preRouteInit()
  # First... As an absolute must.
  # Check if the registrations are open.
  # I don't know how I missed this obvious flaw
  # the first time I wrote this route.
  if not config.getBoolOrDefault("user","registrations_open", true):
    resp renderWithExtras(
      "signup.html",
      @[("signup_enabled": $(config.getBoolOrDefault("user","registrations_open",true)))]
    )
    return
  
  # Let's first check for required options.
  # Everything else will come later.
  if not ctx.isValidFormParam("user"):
    resp renderError("Missing or invalid username.","signup.html")
    return

  if not ctx.isValidFormParam("pass"):
    resp renderError("Missing or invalid password.","signup.html")
    return

  # Then let's check if the username exists.
  if db.userHandleExists(ctx.getFormParam("user")):
    resp renderError("Another user with the same handle already exists","signup.html")
    return
  
  var email = ""
  when not defined(phPrivate):
    if not ctx.isValidFormParam("email"):
      resp renderError("Missing or invalid email.","signup.html")
      return
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
  if config.getBoolOrDefault("user","require_approval",false):
    user.is_approved = false # User isn't allowed to login until their account is approved.

  try:
    db.addUser(user)
    resp renderSuccess("Your account has been successfully registered.","signup.html")
  except CatchableError as err:
    resp renderError("Account registration failed! Ask for help from administrator!\nError: " & err.msg,"signup.html")

proc get_auth_signin*(ctx: Context) {.async.} =
  preRouteInit()
  resp render("signin.html")

proc post_auth_signin*(ctx: Context) {.async.} =
  preRouteInit()

  # Let's first check for required options.
  # Everything else will come later.
  if not ctx.isValidFormParam("user"):
    resp renderError("Missing or invalid username.","signin.html")
    return

  if not ctx.isValidFormParam("pass"):
    resp renderError("Missing or invalid password.","signin.html")
    return

  # Check if user exists
  if not db.userHandleExists(sanitizeHandle(ctx.getFormParam("user"))):
    resp renderError("User does not exist.","signin.html")
    return

  let user = db.getUserByHandle(sanitizeHandle(ctx.getFormParam("user")))

  # Disable login if account is frozen or not yet approved.
  if user.is_frozen:
    resp renderError("Your account has been frozen, contact the administrators of this instance.","signin.html")
    return
  
  if not user.is_approved and config.getBool("user","require_approval") == true:
    resp renderError("Your account has not been approved yet. Contact the administrators of this instance.","signin.html")
    return
  

  # TODO: Implement this once postgres is stable
  # Session tokens will be stored in a separate table.
  # consisting of the following schema:
  # "user": BLOB NOT NULL, # Id of token's user.
  # "token": "BLOB NOT NULL", # The actual token itself.
  # "written": "TIMESTAMP NOT NULL", # Timestamp of when the token was last used. If it hasn't been used in more than two weeks then kill it with fire.
  # "ip": "BLOB NOT NULL" # A hash of the user's IP address. On phPrivate, this is not used whatsoever.
  # "salt": "BLOB UNIQUE NOT NULL" # A small salt used to hash the user's IP address
  
  resp renderError("Login is not implemented yet... Sorry! ;( But here is some debugging info: " & $user,"signin.html")

proc render_reactions_html*(db: DbConn, folder: string, id: string): string =
  ## This procedure renders a file named "reaction.html", it's used to provide the reaction stats for posts.
  for reaction, reactors in db.getReactions(id).pairs:
    let table = {
      "post_link": "/notice/" & id,
      "react_id": reaction,
      "reactors": $len(reactors)
    }.toTable

    result.add(
      templateify(getAsset(folder, "reaction.html"), table)
    )

  return result

proc render_profile_html*(ctx: Context) {.async, gcsafe.} =
  preRouteInit()
  # Some basic checks
  if not ctx.isValidPathParam("user"):
    resp renderError("Invalid user")
    return

  if db.userHandleExists(sanitizeHandle(ctx.getPathParam("user"))) == false:
    resp renderError("User does not exist")
    return
  
  let user = db.getUserByHandle(sanitizeHandle(ctx.getPathParam("user")))

  # First off, we retrieve a list of posts made by the user
  var posts = "<div class=\"posts\">"
  for i in db.getPostsByUserId(user.id, 10):
    # Start by getting reactions, boosts and so on.
    posts.add("<div class=\"post\">")
    var table = {
      "user_link": "/users/" & user.handle,
      "avatar": config.getAvatar(user.id),
      "name": user.name,
      "handle": user.handle,
      "post_content": i.content,
      "post_attachments": "TODO! Fix this, post_attachments",
      "post_link": "/notice/" & i.id,
      "post_date": formatDate(i.written),
      "post_updated": "", # Will be filled later. TODO
      "client_name": db.getClientName(i.client),
      "client_link": db.getClientLink(i.client),
      "reactions": render_reactions_html(db, templatesFolder, i.id),
      "boosts": $len(db.getBoostsQuickWithHandle(i.id)),
      "replies_num": $db.getNumOfReplies(i.id)
    }.toTable

    {.gcsafe.}:
      posts.add(
        templateify(getAsset(templatesFolder, "post.html"), table)
      )
    posts.add("</div>")
  posts.add("</div>")

  var table = {
    "handle": user.handle,
    "name": user.name,
    "avatar": config.getAvatar(user.id),
    "posts": posts,
    "page_num": "TODO! Pagination",
    "user_back": "TODO! Pagination",
    "user_forward": "TODO! Pagination"
  }.toTable

  resp templateify(getAsset(templatesFolder, "user.html"), table)

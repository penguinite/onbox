# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
# Copyright © penguinite 2024 <penguinite@tuta.io>
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
import pothole/[conf, assets, database, routeutils, lib]

# From somewhere in the standard library
import std/[tables, mimetypes, os]

# From nimble/other sources
import mummy, waterpark/postgres, rng

const renderURLs*: Table[string,string] = {
  "/": "index.html", 
  "/about": "about.html", "/about/more": "about.html", # About pages, they run off of the same template.
  "/auth/sign_in": "signin.html",
  "/auth/sign_up": "signup.html"
}.toTable

proc serveAndRender*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  
  var path = req.path
  if path[high(path)] == '/' and path != "/":
    path = path[0..^2] # Remove last slash at the end of the path
  
  templatePool.withConnection obj:
    req.respond(
      200, headers,
      obj.render(renderURLs[path])
    )

proc serveStatic*(req: Request) =
  var headers: HttpHeaders

  let (dir, file, ext) = splitFile(req.path)
  discard dir # Fucking nim.
  templatePool.withConnection obj:
    headers["Content-Type"] = mimedb.getMimetype(ext)
    if ext == ".css":
      # Special case for CSS files.
      req.respond(200, headers, getAsset(obj.staticFolder, "style.css"))
    else:
      if not fileExists(obj.staticFolder & file & ext):
        headers["Content-Type"] = "text/html"
        req.respond(404, headers, renderError(obj.templatesFolder, "File couldn't be found."))
        return
      req.respond(200, headers, readFile(obj.staticFolder & file & ext))

proc signUp*(req: Request) =
  var
    fm: FormEntries
    headers: HttpHeaders

  # Check first, if sign ups are enabled.
  configPool.withConnection config:
    if not config.getBoolOrDefault("user", "registrations_open", true):
      templatePool.withConnection obj:
        req.respond(401, headers, renderError(obj.templatesFolder, "Signups are disabled on this instance!"))
        return

  headers["Content-Type"] = "text/html"
  try:
    fm = req.unrollForm()
  except CatchableError as err:
    log "Couldn't process request: ", err.msg
    templatePool.withConnection obj:
      req.respond(401, headers, renderError(obj.templatesFolder, "Couldn't process request."))
      return
  
  # Check first if user, email and password exist.
  # Thats the minimum we need for a user.
  if not fm.isValidFormParam("user") or not fm.isValidFormParam("email") or not fm.isValidFormParam("pass"):
    templatePool.withConnection obj:
      req.respond(401, headers, renderError(obj.templatesFolder, "Missing required fields. Make sure the Username, Password and Email fields are filled out."))
    return

  var
    username = sanitizeHandle(fm.getFormParam("user"))
    email = fm.getFormParam("email") # There isn't really any point to sanitizing emails...
    password = fm.getFormParam("pass")
  
  var display_name = username
  if fm.isValidFormParam("name"):
    display_name = fm.getFormParam("name")
  
  var bio = ""
  if fm.isValidFormParam("bio"):
    bio = fm.getFormParam("bio")
  
  var user = newUser(username, true, password)
  user.name = display_name
  user.email = email
  user.bio = bio

  var require_approval: bool
  configPool.withConnection config:
    require_approval = config.getBoolOrDefault("user", "require_approval", false)

  if require_approval:
    user.is_approved = false
  else:
    user.is_approved = true

  try:
    dbPool.withConnection db:
      db.addUser(user)
  except CatchableError as err:
    var id = randstr(10)
    log "(ID: \"", id, "\") Couldn't insert user: ", err.msg
    templatePool.withConnection obj:
      req.respond(500, headers, renderError(obj.templatesFolder, "Couldn't register account! Contact the instance administrator, error id: " & id))
  
  var msg = "Success! Your account has been registered!"
  if require_approval:
    msg.add " but you will have to wait for an administrator to approve it before you can log in."
  
  templatePool.withConnection obj:
    req.respond(200, headers, renderSuccess(obj.templatesFolder, msg))
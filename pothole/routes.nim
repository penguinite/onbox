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
import quark/[user, post, crypto]

# From somewhere in Pothole
import pothole/[conf, assets, database, routeutils, lib]

# From somewhere in the standard library
import std/[tables, mimetypes, os]
from std/strutils import startsWith

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
  

  # If the user has a cookie, then let the templating engine know.
  # signin.html and signup.html have some login-related conditionals in the template.
  if req.hasSessionCookie():
    # Fetch user handle and verify cookie before sending it to the template.
    var user = ""
    let session = req.fetchSessionCookie()
    dbPool.withConnection db:
      if db.sessionExists(session):
        user = db.getSessionUserHandle(session)

    templatePool.withConnection obj:
      req.respond(
        200, headers,
        obj.render(renderURLs[path], {"login": user})
      )
  else:
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
        req.respond(404, headers, renderError(obj, "File couldn't be found."))
        return
      req.respond(200, headers, readFile(obj.staticFolder & file & ext))

proc signUp*(req: Request) =
  var
    fm: FormEntries
    headers: HttpHeaders
  headers["Content-Type"] = "text/html"

  # Check if the user is already logged in.
  if req.hasSessionCookie():
    templatePool.withConnection obj:
      req.respond(
        400, headers, 
        obj.renderError("You are already logged in.","signin.html"))
    return

  # Then check, if sign ups are enabled.
  configPool.withConnection config:
    if not config.getBoolOrDefault("user", "registrations_open", true):
      templatePool.withConnection obj:
        req.respond(
          400, headers, 
          obj.renderError("Signups are disabled on this instance!", "signup.html"))
        return
  
  # Unroll form submission data.
  try:
    fm = req.unrollForm()
  except CatchableError as err:
    log "Couldn't process request: ", err.msg
    templatePool.withConnection obj:
      req.respond(
        400, headers,
        obj.renderError("Couldn't process requests!","signup.html"))
      return
  
  # Check first if user, email and password exist.
  # Thats the minimum we need for a user.
  if not fm.isValidFormParam("user") or not fm.isValidFormParam("email") or not fm.isValidFormParam("pass"):
    templatePool.withConnection obj:
      req.respond(
        400, headers, 
        obj.renderError("Missing required fields. Make sure the Username, Password and Email fields are filled out properly.","signup.html"))
    return

  # Then, just retrieve all the data we need.
  var
    username = fm.getFormParam("user")
    email = fm.getFormParam("email") # There isn't really any point to sanitizing emails...
    password = fm.getFormParam("pass")
  
  # If a display name hasn't been submitted then
  # just use the username as fallback
  var display_name = username
  if fm.isValidFormParam("name"):
    display_name = fm.getFormParam("name")
  
  # If bio hasn't been submitted then just keep it empty.
  # Its not that important...
  var bio = ""
  if fm.isValidFormParam("bio"):
    bio = fm.getFormParam("bio")
  
  # Create the user and add in all the stuff
  # we have.
  var user = newUser(username, true, password)
  user.name = display_name
  user.email = email
  user.bio = bio

  # If the instance requires approval
  # then set is_approved to false
  # otherwise set it to true
  var require_approval: bool
  configPool.withConnection config:
    require_approval = config.getBoolOrDefault("user", "require_approval", false)

  if require_approval:
    user.is_approved = false
  else:
    user.is_approved = true

  # Check if a user like this already exists.
  dbPool.withConnection db:
    if db.userHandleExists(user.handle):
      templatePool.withConnection obj:
        req.respond(
          400, headers, 
          obj.renderError("User with the same username already exists!", "signup.html"))
        return
    

  # Finally, insert the user
  try:
    dbPool.withConnection db:
      db.addUser(user)
  except CatchableError as err:
    # if we fail, for whatever reason, then log it with an id.
    # and give the id back to the user so that they can
    # ask the admin what went wrong.
    var id = randstr(10)
    log "(ID: \"", id, "\") Couldn't insert user: ", err.msg
    templatePool.withConnection obj:
      req.respond(
        500, headers, 
        obj.renderError("Couldn't register account! Contact the instance administrator, error id: " & id, "signup.html"))
    return
  
  var msg = "Success! Your account has been registered!"
  if require_approval:
    msg = msg[0..^2]
    msg.add " but you will have to wait for an administrator to approve it before you can log in."
  
  # All went well... We now have a user on the instance!
  templatePool.withConnection obj:
    req.respond(
      500, headers, 
      obj.renderSuccess(msg, "signup.html"))

proc signIn*(req: Request) =
  var
    fm: FormEntries
    headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  
  # Check if the user is already logged in.
  if req.hasSessionCookie():
    templatePool.withConnection obj:
      req.respond(
        400, headers, 
        obj.renderError("You are already logged in.","signin.html"))
    return

  # Unroll form submission data.
  try:
    fm = req.unrollForm()
  except CatchableError as err:
    log "Couldn't process request: ", err.msg
    templatePool.withConnection obj:
      req.respond(
        400, headers,
        obj.renderError("Couldn't process requests!","signin.html"))
      return

  # Check first if user and password exist.
  if not fm.isValidFormParam("user") or not fm.isValidFormParam("pass"):
    templatePool.withConnection obj:
      req.respond(
        400, headers, 
        obj.renderError("Missing required fields. Make sure the Username and Password fields are filled out properly.","signin.html"))
    return


  # Then, see if the user exists at all via handle or email.
  var id = ""
  dbPool.withConnection db:
    var user = fm.getFormParam("user")
    if db.userEmailExists(user):
      id = db.getUserIdByEmail(user)
    
    if db.userHandleExists(sanitizeHandle(user)):
      id = db.getIdFromHandle(sanitizeHandle(user))
  
  if id == "":
    templatePool.withConnection obj:
      req.respond(
        404, headers, 
        obj.renderError("User doesn't exist!","signin.html"))
    return

  # Then retrieve various stuff from the database.
  var
    hash, salt = ""
    kdf = crypto.kdf
  dbPool.withConnection db:
    salt = db.getUserSalt(id)
    kdf = db.getUserKDF(id)
    hash = db.getUserPass(id)
  
  # Finally, compare the hashes.
  if hash != crypto.hash(fm.getFormParam("pass"), salt, kdf):
    templatePool.withConnection obj:
      req.respond(
        400, headers, 
        obj.renderError("Invalid password!","signin.html"))
    return

  # And then, see if we need to update the hash
  # Since we have the password in memory
  if kdf != crypto.kdf:
    log "Updating password hash from KDF:", $kdf, " to KDF:", crypto.kdf, " for user \"", id, "\""
    var newhash = crypto.hash(
      fm.getFormParam("pass"),
      salt, crypto.kdf
    )

    dbPool.withConnection db:
      db.updateUserById(
        id, "password", newhash
      )

  if fm.isValidFormParam("rememberme"):
    var session: string
    let date = utc(now() + 400.days) # 400 days is the upper limit on cookie age for chrome.
    dbPool.withConnection db:
      session = db.createSession(id)
    # This is a lengthy one-liner, maybe replace it with something more concise?
    headers["Set-Cookie"] = "session=" & session & "; Path=/; Priority=High; sameSite=Strict; Secure; HttpOnly; Expires=" & date.format("ddd") & ", " & date.format("dd MMM hh:mm:ss") & " GMT"

  # If there is no need for redirection
  # then just proceed, and render the "You have logged in!" page
  if not req.isValidQueryParam("return_to"):
    templatePool.withConnection obj:
      req.respond(
        200, headers,
        obj.renderSuccess("Successful login!", "signin.html")
      )
    return

  # User has requested to return to some place.
  let loc = req.getQueryParam("return_to")

  # If the return_to starts with javascript: or data:
  # then it might be some form of XSS attack and its best to not
  # continue redirecting.
  if loc.startsWith("javascript:") or loc.startsWith("data:"):
    templatePool.withConnection obj:
      req.respond(
        400,
        headers,
        obj.renderError("There might be some form of XSS attack going on, we'll end the request just to be safe. But your login was successful!", "signin.html")
      )
    return

  headers["Location"] = loc
  templatePool.withConnection obj:
    req.respond(
      303, headers,
      obj.renderSuccess("Successful login, redirecting...", "signin.html")
    )

proc checkSession*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"

  var msg = "Not logged in at all"

  if req.hasSessionCookie():
    msg = "Logged in as "
    dbPool.withConnection db:
      msg.add(db.getSessionUserHandle(req.fetchSessionCookie()))

  templatePool.withConnection obj:
    req.respond(
      200, headers,
      obj.render(
        "check.html",
        {
          "title": "Login check",
          "message": msg
        }
      )  
    )

proc logoutSession*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"

  # Remove session cookie from user's browser.
  if req.hasSessionCookie():
    headers["Set-Cookie"] = deleteSessionCookie()
    # Check if it actaully exists in the db before removing.
    # In theory this shouldn't matter but its a good thing to do anyway
    dbPool.withConnection db:
      let id = req.fetchSessionCookie()
      if db.sessionExists(id):
        db.deleteSession(id)

  # Just render homepage. We dont have a dedicated page for this.
  templatePool.withConnection obj:
    req.respond(
      200, headers,
      obj.renderSuccess("index.html", "Successfully logged out!")
    )


const urlRoutes* = {
  "/auth/sign_up": ("POST", signUp),
  "/auth/sign_in": ("POST", signIn),
  "/auth/check": ("GET", checkSession),
  "/auth/logout": ("GET", logoutSession),
}.toTable

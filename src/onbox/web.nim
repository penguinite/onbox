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
import onbox/db/[users, posts, sessions]
import onbox/[conf, assets, routes, database, crypto, shared]

# API routes!
import onbox/api/[instance, apps, oauth, nodeinfo, accounts, email, followed_tags, timelines, statuses]

# From somewhere in the standard library
import std/[tables, strutils, times]

# From nimble/other sources
import mummy, temple, waterpark, waterpark/postgres, iniplus

proc signInGet*(req: Request) =
  var headers = createHeaders("text/html")

  var login = ""
  if req.hasSessionCookie(): login = "true"

  req.respond(
    200, headers,
    templateify(getBuiltinAsset("signin.html"), {"login": login}.toTable)
  )

proc signInPost*(req: Request) =
  var
    headers = createHeaders("text/html")
    fm: FormEntries

  template renderError(err: string) =
    req.respond(400, headers, templateWithAsset("signin.html", {"message_type": "error", "message": err}))
    return

  template renderSuccess(msg: string, code = 200) =
    req.respond(code, headers, templateWithAsset("signin.html", {"message_type": "success", "message": msg}))
    return

  if req.hasSessionCookie():
    renderError("You are already logged in.")

  try:
    fm = req.unrollForm()
  except CatchableError as err:
    log "Couldn't process request: ", err.msg
    renderError("Couldn't process request, unknown error when unrolling form.")

  # Check first if user and password exist.
  if not fm.formParamExists("user") or not fm.formParamExists("pass"):
    renderError("Missing required fields. Make sure the Username and Password fields are filled out properly.")

  # Then, see if the user exists at all via handle or email.
  var id = ""
  dbPool.withConnection db:
    var user = fm["user"]
    if db.userEmailExists(user):
      id = db.getUserIdByEmail(user)
    
    if db.userHandleExists(sanitizeHandle(user)):
      id = db.getIdFromHandle(sanitizeHandle(user))
  
  if id == "":
    renderError("User doesn't exist!")

  # Then retrieve various stuff from the database.
  var
    hash, salt: string
    kdf: KDF

  dbPool.withConnection db:
    if db.userFrozen(id):
      renderError("Your account has been frozen. Contact an administrator.")

    if not db.userApproved(id):
      renderError("Your account hasn't been approved yet, please wait or contact an administrator.")

    configPool.withConnection config:
      if not db.userVerified(id) and config.getBoolOrDefault("user", "require_verification", false):
        ## TODO: Send a code if there hasn't been one yet
        ## TODO: Allow for re-sending codes, say, if a user logins 10 mins after their previous code and still isn't verified.
        renderError("Your account hasn't been verified yet. Check your email for a verification link.")

    salt = db.getUserSalt(id)
    kdf = db.getUserKDF(id)
    hash = db.getUserPass(id)
  
  # Finally, compare the hashes.
  if hash != crypto.hash(fm["pass"], salt, kdf):
    renderError("Invalid password!")

  # And then, see if we need to update the hash
  # Since we have the password in memory
  if kdf != crypto.latestKdf:
    log "Updating password hash from KDF:", $kdf, " to KDF:", crypto.latestKdf, " for user \"", id, "\""
    dbPool.withConnection db:
      db.updateUserById(
        id, "password",
        crypto.hash(
          fm["pass"], salt, crypto.latestKdf
        )
      )

  if fm.formParamExists("rememberme"):
    var session: string
    let date = utc(now() + 400.days) # 400 days is the upper limit on cookie age for chrome.
    dbPool.withConnection db:
      session = db.createSession(id)
    # This is a lengthy one-liner, maybe replace it with something more concise?
    headers["Set-Cookie"] = "session=" & session & "; Path=/; Priority=High; sameSite=Strict; Secure; HttpOnly; Expires=" & date.format("ddd") & ", " & date.format("dd MMM hh:mm:ss") & " GMT"

  # If there is no need for redirection
  # then just proceed, and render the "You have logged in!" page
  if not req.queryParamExists("return_to"):
    renderSuccess("Successful login!")

  # User has requested to return to some place.
  let loc = req.queryParams["return_to"]

  # If the return_to starts with javascript: or data:
  # then it might be some form of XSS attack and its best to not
  # continue redirecting.
  if loc.startsWith("javascript:") or loc.startsWith("data:"):
    renderSuccess("Your login *was* successful but we detected a sort-of XSS attack going on, so we didn't redirect you to your final destination.")

  headers["Location"] = loc
  renderSuccess("Successful login, redirecting...", code = 303)

proc logoutSession*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"

  # Remove session cookie from user's browser.
  if req.hasSessionCookie():
    headers["Set-Cookie"] = "session=\"\"; path=/; Max-Age=0"
    # Check if it actaully exists in the db before removing.
    # In theory this shouldn't matter but its a good thing to do anyway
    dbPool.withConnection db:
      let id = req.fetchSessionCookie()
      if db.sessionExists(id):
        db.deleteSession(id)

  # Just render the homepage
  # Since we dont have a dedicated page for this kinda thing.
  req.respond(200, headers,getBuiltinAsset("home.html"))

proc serveCSS*(req: Request) = 
  var headers: HttpHeaders
  headers["Content-Type"] = "text/css"
  req.respond(200, headers, getBuiltinAsset("style.css"))

proc serveHome*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  req.respond(200, headers, getBuiltinAsset("home.html"))


const mummyRoutes* =  @[
  # (URLRoute, HttpMethod, RouteProcedure)
  ("/static/style.css", "GET", serveCSS),
  ("/auth/sign_in", "GET", signInGet),
  ("/auth/sign_in", "POST", signInPost),
  ("/auth/logout", "GET", logoutSession),
  ("/api/v1/instance", "GET", v1InstanceView),
  ("/api/v2/instance", "GET", v2InstanceView),
  ("/api/v1/instance/rules", "GET", v1InstanceRules),
  ("/api/v1/instance/extended_description", "GET", v1InstanceExtendedDescription),
  ("/api/v1/apps", "POST", v1Apps),
  ("/api/v1/apps/verify_credentials", "GET", v1AppsVerify),
  ("/oauth/authorize", "GET" , oauthAuthorizeGET),
  ("/oauth/authorize", "POST" , oauthAuthorizePOST),
  ("/oauth/token",  "POST", oauthToken),
  ("/oauth/revoke",  "POST", oauthRevoke),
  ("/.well-known/oauth-authorization-server", "GET", oauthInfo),
  ("/.well-known/nodeinfo", "GET", resolveNodeinfo),
  ("/nodeinfo/2.0", "GET", nodeInfo2x0),
  ("/api/v1/emails/confirmations", "POST", emailConfirmation),
  ("/api/v1/accounts/verify_credentials",  "GET", accountsVerifyCredentials),
  ("/api/v1/accounts/@id", "GET", accountsGet),
  ("/api/v1/accounts", "GET", accountsGetMultiple),
  ("/api/v1/followed_tags", "GET", followedTags),
  ("/api/v1/timelines/home", "GET", timelinesHome),
  ("/api/v1/statuses/@id/reblog", "POST", boostStatus),
  ("/api/v1/statuses/@id/unreblog", "POST", unboostStatus),
  ("/api/v1/statuses/@id/bookmark", "POST", bookmarkStatus),
  ("/api/v1/statuses/@id/unbookmark", "POST", unbookmarkStatus),
  ("/api/v1/statuses/@id", "GET", viewStatus),
]
# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
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
# onbox/api/oauth.nim:
## This module contains all the routes for the oauth method in the api

# TODO: This module's migration to the new db layer wasn't so smooth
# Also I hear that there are new changes, so we must update.

# From somewhere in Onbox
import onbox/db/[apps, oauth, sessions, users, auth_codes], onbox/[conf, assets, routes, strextra]

# From somewhere in the standard library
import std/[json, strutils]

# From nimble/other sources
import mummy, temple, iniplus, waterpark/postgres

proc success(msg: string): Table[string, string] =
  ## Returns a table suitable for further processing in templateify()
  return {
    "title": "Success!",
    "message_type": "success",
    "message": msg
  }.toTable

proc getSeparator(s: string): char =
  ## When given a string containing a set of separated scopes, it tries to find out what the separator is.
  ## This is needed because the Mastodon API allows the use of + signs and spaces as separators.
  ## Personally, I think this is fucking stupid, and it would have made everything easier to just use one symbol.
  for ch in s:
    case ch:
    of '+': return '+'
    of ' ': return ' '
    else: continue
  return ' ' # If a separator can't be found, then it's safe to assume it's a space-separated scope.

proc renderAuthForm(req: Request, scopes: seq[string], client_id, redirect_uri: string) =
  ## A function to render the auth form.
  ## I don't want to repeat myself 2 times in the POST and GET section so...
  ## here it is.
  var human_scopes = ""
  for scope in scopes:
    human_scopes.add(
      "<li>" & scope & ": " & humanizeScope(scope) & "</li>"
    )
  
  let session = req.fetchSessionCookie()
  var appname, login = ""
  dbPool.withConnection db:
    appname = db.getClientName(client_id)
    login = db.getHandleFromId(db.getSessionUser(session))

  req.respond(
    200, createHeaders("text/html"),
    templateify(
      getBuiltinAsset("oauth.html"),
      {
        "human_scope": human_scopes,
        "scope": scopes.join(" "),
        "login": login,
        "session": session,
        "client_id": client_id,
        "redirect_uri": redirect_uri
      }.toTable
    )
  )

template redirectToLogin*(req: Request, headers: var HttpHeaders, client, redirect_uri: string, scopes: seq[string], force_login: bool) =
  # If the client has requested force login then remove the session cookie.
  if force_login:
    headers["Set-Cookie"] = "session=\"\"; path=/; Max-Age=0"

  configPool.withConnection config:
    let url = realURL(config)
    headers["Location"] = url & "auth/sign_in/?return_to=" & encodeQueryComponent("$#oauth/authorize?response_type=code&client_id=$#&redirect_uri=$#&scope=$#&lang=en" % [url, client, redirect_uri, scopes.join(" ")])
  req.respond(303, headers, "")
  return

proc oauthAuthorizeGET*(req: Request) =
  var headers = createHeaders("application/json")
  # If response_type exists
  if not req.queryParamExists("response_type"):
    respJsonError("Missing required field: response_type")
  
  # If response_type doesn't match "code"
  if req.queryParams["response_type"] != "code":
    respJsonError("Required field response_type has been set to an invalid value.")

  # If client id exists
  if not req.queryParamExists("client_id"):
    respJsonError("Missing required field: response_type")

  # If redirect_uri exists
  if not req.queryParamExists("redirect_uri"):
    respJsonError("Missing required field: redirect_uri")
  var redirect_uri = htmlEscape(req.queryParams["redirect_uri"])

  # Check if client_id is associated with a valid app
  var client_id = req.queryParams["client_id"]
  dbPool.withConnection db:
    if not db.clientExists(client_id):
      respJsonError("Client_id isn't registered to a valid app.")

    # Check if redirect_uri matches the redirect_uri for the app
    if redirect_uri notin db.getClientUris(client_id):
      respJsonError("The redirect_uri used doesn't match the one provided during app registration")

  var
    scopes = @["read"]
    scopeSeparator = ' '
  if req.queryParamExists("scope"):
    # According to API, we can either split by + or space.
    # so we run this to figure it out. Defaulting to spaces if needed
    scopeSeparator = getSeparator(req.queryParams["scope"])
    scopes = req.queryParams["scope"].split(scopeSeparator)
  
    for scope in scopes:
      # Then verify if every scope is valid.
      if not scope.verifyScope():
        respJsonError("Invalid scope: \"" & scope & "\" (Separator: " & scopeSeparator & ")")

  dbPool.withConnection db:
    # And then we see if the scopes have been specified during app registration
    # This isn't in the for loop above, since this uses db calls, and I don't wanna
    # flood the server with excessive database calls.
    if not db.hasScopes(client_id, scopes):
      respJsonError("An attached scope wasn't specified during app registration.")
  
  var force_login = false
  if req.queryParamExists("force_login"):
    try:
      force_login = req.queryParams["force_login"].parseBool()
    except:
      force_login = true
  
  #var lang = "en" # Unused and unparsed. TODO: Implement checks for this.

  # Check for authorization or "force_login" parameter
  # If auth isnt present or force_login is true then redirect user to the login page
  if not req.hasSessionCookie() or force_login:
    req.redirectToLogin(headers, client_id, redirect_uri, scopes, force_login)

  dbPool.withConnection db:
    if not db.sessionExists(req.fetchSessionCookie()):
      req.redirectToLogin(headers, client_id, redirect_uri, scopes, force_login)

  req.renderAuthForm(scopes, client_id, redirect_uri)

proc oauthAuthorizePOST*(req: Request) =
  var headers = createHeaders("application/json")
  let fm = req.unrollForm()

  # If response_type exists
  if not fm.formParamExists("response_type"):
    respJsonError("Missing required field: response_type")
  
  # If response_type doesn't match "code"
  if fm["response_type"] != "code":
    respJsonError("Required field response_type has been set to an invalid value.")

  # If client id exists
  if not fm.formParamExists("client_id"):
    respJsonError("Missing required field: response_type")

  # Check if client_id is associated with a valid app
  dbPool.withConnection db:
    if not db.clientExists(fm["client_id"]):
      respJsonError("Client_id isn't registered to a valid app.")
  var client_id = fm["client_id"]
  
  # If redirect_uri exists
  if not fm.formParamExists("redirect_uri"):
    respJsonError("Missing required field: redirect_uri")
  var redirect_uri = htmlEscape(fm["redirect_uri"])

  # Check if redirect_uri matches the redirect_uri for the app
  dbPool.withConnection db:
    if redirect_uri notin db.getClientUris(client_id):
      respJsonError("The redirect_uri used doesn't match the one provided during app registration")

  var
    scopes = @["read"]
    scopeSeparator = ' '
  if fm.formParamExists("scope"):
    # According to API, we can either split by + or space.
    # so we run this to figure it out. Defaulting to spaces if need
    scopeSeparator = getSeparator(fm["scope"])
    scopes = fm["scope"].split(scopeSeparator)
  
    for scope in scopes:
      # Then verify if every scope is valid.
      if not scope.verifyScope():
        respJsonError("Invalid scope: \"" & scope & "\" (Separator: " & scopeSeparator & ")")

  dbPool.withConnection db:
    # And then we see if the scopes have been specified during app registration
    # This isn't in the for loop above, since this uses db calls, and I don't wanna
    # flood the server with excessive database calls.
    if not db.hasScopes(client_id, scopes):
      respJsonError("An attached scope wasn't specified during app registration.")
  
  var force_login = false
  if fm.formParamExists("force_login"):
    try:
      force_login = fm["force_login"].parseBool()
    except:
      force_login = true
  
  # Check for authorization or "force_login" parameter
  # If auth isnt present or force_login is true then redirect user to the login page
  if not req.hasSessionCookie() or force_login:
    req.redirectToLogin(headers, client_id, redirect_uri, scopes, force_login)
  
  dbPool.withConnection db:
    if not db.sessionExists(req.fetchSessionCookie()):
      req.redirectToLogin(headers, client_id, redirect_uri, scopes, force_login)

  if not fm.formParamExists("action"):
    req.renderAuthForm(scopes, client_id, redirect_uri)
    return
  
  var user = ""
  dbPool.withConnection db:
    user = db.getSessionUser(req.fetchSessionCookie())
    if db.authCodeExists(user, client_id):
      db.deleteAuthCode(
        db.getSpecificAuthCode(user, client_id)
      )

  case fm["action"].toLowerAscii():
  of "authorized":
    var code = ""

    dbPool.withConnection db:
      code = db.createAuthCode(user, client_id, scopes)
    
    if redirect_uri == "urn:ietf:wg:oauth:2.0:oob":
      ## Show code to user
      var headers: HttpHeaders
      headers["Content-Type"] = "text/html"
      req.respond(
        200, headers,
        templateify(
          getBuiltinAsset("generic.html"),
          success("Authorization code: " & code)
        )
      )

    else:
      ## Redirect them elsewhere
      var headers: HttpHeaders
      headers["Location"] = redirect_uri & "?code=" & code

      req.respond(
        303, headers, ""
      )
      return
  else:
    # There's not really anything to do.
    var headers: HttpHeaders
    headers["Content-Type"] = "text/html"
    req.respond(
      200, headers,
      templateify(
        getBuiltinAsset("generic.html"),
        success("Authorization request has been rejected!")
      )
    )

proc oauthToken*(req: Request) =
  var json: JsonNode
  try: json = req.fetchReqBody()
  except: return

  for param in ["client_id", "client_secret", "redirect_uri", "grant_type"]:
    if not json.hasValidStrKey(param):
      respJsonError("Missing required parameter: " & param)

  var
    grant_type = json["grant_type"].getStr()
    client_id = json["client_id"].getStr()
    client_secret = json["client_secret"].getStr()
    redirect_uri = json["redirect_uri"].getStr()
    code = json["code"].getStr("")
    # A gross one-liner
    # A client may separate scopes by space or the "+" sign
    scopes = json["scope"].getStr("read").split(getSeparator(json["scope"].getStr("read")))

  # Verify the provided scopes.
  for scope in scopes:
    if not scope.verifyScope():
      respJsonError("Invalid scope: " & scope)

  # Verify the provided grant-type
  if grant_type notin ["authorization_code", "client_credentials"]:
    respJsonError("Unknown grant_type")
  
  var token = ""
  dbPool.withConnection db:
    if not db.clientExists(client_id):
      respJsonError("Client doesn't exist")
    
    if db.getClientSecret(client_id) != client_secret:
      respJsonError("Client secret doesn't match client id")
    
    if redirect_uri notin db.getClientUris(client_id):
      respJsonError("Redirect_uri not specified during app creation")
    
    if not db.hasScopes(client_id, scopes):
        respJsonError("An attached scope wasn't specified during app registration.")
    
    if grant_type == "authorization_code":
      if not db.authCodeValid(code):
        respJsonError("Invalid code")
      
      scopes = db.getCodeScopes(code)
      if not db.codeHasScopes(code, scopes):
        respJsonError("An attached scope wasn't specified during oauth authorization.")
    
    token = db.createToken(client_id, db.getUserFromAuthCode(code), scopes)
    db.deleteAuthCode(code) # Delete auth code after we are done
  
  req.respond(
    200, createHeaders("application/json"),
    $(%*{
      "access_token": token,
      "token_type": "Bearer",
      "scope": scopes.join(" "),
      "created_at": 0
    })
  )
  
proc oauthRevoke*(req: Request) =
  ## We gotta check for both url-form-encoded or whatever
  ## And for JSON body requests.
  var json: JsonNode
  try: json = req.fetchReqBody()
  except: return

  for param in ["client_id", "client_secret", "token"]:
    if not json.hasValidStrKey(param):
      respJsonError("Missing required parameter: " & param)

  let
    client_id = json["client_id"].getStr()
    client_secret = json["client_secret"].getStr()
    token = json["token"].getStr()

  # Now we check if the data submitted is actually valid.
  dbPool.withConnection db:
    if not db.clientExists(client_id):
      respJsonError("Client doesn't exist", 403)
      
    if not db.tokenExists(token):
      respJsonError("Token doesn't exist.", 403)

    if db.getTokenApp(token) != client_id:
      respJsonError("Client doesn't own this token", 403)

    if db.getClientSecret(client_id) != client_secret:
      respJsonError("Client secret doesn't match client id", 403)

    # Finally, delete the OAuth token.
    db.deleteOAuthToken(token)
  req.respond(200, createHeaders("application/json"), "{}")
  
proc oauthInfo*(req: Request) =
  var url = ""
  configPool.withConnection config:
    url = realURL(config)

  respJson($(
    %*{
      "issuer": url,
      "service_documentation": "https://docs.joinmastodon.org/",
      "authorization_endpoint": url & "oauth/authorize",
      "token_endpoint": url & "oauth/token",
      "app_registration_endpoint": url & "api/v1/apps",
      "revocation_endpoint": url & "oauth/revoke",
      # I had to write this manually
      # TODO: It would be nice if we had a way to automate this of some sort.
      "scopes_supported": ["read", "write", "push", "follow", "admin:read", "admin:write", "read:accounts", "read:blocks", "read:bookmarks", "read:favorites", "read:favourites", "read:filters", "read:follows", "read:lists", "read:mutes", "read:notifications", "read:search", "read:statuses", "wite:accounts", "wite:blocks", "wite:bookmarks", "wite:favorites", "wite:favourites", "wite:filters", "wite:follows", "wite:lists", "wite:mutes", "wite:notifications", "wite:search", "wite:statuses", "admin:write:accounts", "admin:write:reports", "admin:write:domain_allows", "admin:write:domain_blocks", "admin:write:ip_blocks", "admin:write:email_domain_blocks", "admin:write:canonical_domain_blocks", "admin:read:accounts", "admin:read:reports", "admin:read:domain_allows", "admin:read:domain_blocks", "admin:read:ip_blocks", "admin:read:email_domain_blocks", "admin:read:canonical_domain_blocks"],
      # The rest we send back as-is, since we don't do things differently.
      "response_types_supported": ["code"],
      "response_modes_supported": ["query", "fragment", "form_post"],
      "code_challenge_methods_supported": ["S256"],
      "grant_types_supported": ["authorization_code", "client_credentials"],
      "token_endpoint_auth_methods_supported": ["client_secret_basic", "client_secret_post"]
    }
  ))
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
# api/oauth.nim:
## This module contains all the routes for the oauth method in the api


# From somewhere in Quark
import quark/[crypto]

# From somewhere in Pothole
import pothole/[lib, database, routeutils, conf]

# From somewhere in the standard library
import std/[json, strutils]

# From nimble/other sources
import mummy

proc getSeparator(s: string): char =
  for ch in s:
    case ch:
    of '+': return '+'
    of ' ': return ' '
    else:
      continue
  return ' '


proc oauthAuthorize*(req: Request) =
  # If response_type exists
  if not req.isValidQueryParam("response_type"):
    respJsonError("Missing required field: response_type")
  
  # If response_type doesn't match "code"
  if req.getQueryParam("response_type") != "code":
    respJsonError("Required field response_type has been set to an invalid value.")

  # If client id exists
  if not req.isValidQueryParam("client_id"):
    respJsonError("Missing required field: response_type")

  # Check if client_id is associated with a valid app
  dbPool.withConnection db:
    if not db.clientExists(req.getQueryParam("client_id")):
      respJsonError("Client_id isn't registered to a valid app.")
  var client_id = req.getQueryParam("client_id")
  
  # If redirect_uri exists
  if not req.isValidQueryParam("redirect_uri"):
    respJsonError("Missing required field: redirect_uri")
  var redirect_uri = req.getQueryParam("redirect_uri")

  # Check if redirect_uri matches the redirect_uri for the app
  dbPool.withConnection db:
    if redirect_uri != db.getClientRedirectUri(client_id):
      respJsonError("The redirect_uri used doesn't match the one provided during app registration")

  var
    scopes = @["read"]
    scopeSeparator = ' '
  if req.isValidQueryParam("scope"):
    # According to API, we can either split by + or space.
    # so we run this to figure it out. Defaulting to spaces if need
    scopeSeparator = getSeparator(req.getQueryParam("scope")) 
    scopes = req.getQueryParam("scope").split(scopeSeparator)
  
  dbPool.withConnection db:
    for scope in scopes:
      # Then verify if every scope is valid.
      if not scope.verifyScope():
        respJsonError("Invalid scope: \"" & scope & "\" (Separator: " & scopeSeparator & ")")

    # And then we see if the scopes have been specified during app registration
    # This isn't in the for loop above, since this uses db calls, and I don't wanna
    # flood the server with excessive database calls.
    if not db.hasScopes(client_id, scopes):
      respJsonError("An attached scope wasn't specified during app registration.")
  
  var force_login = false
  if req.isValidQueryParam("force_login"):
    try:
      force_login = req.getQueryParam("force_login").parseBool()
    except:
      force_login = true
  
  #var lang = "en" # Unused and unparsed. TODO: Implement checks for this.

  # Check for authorization
  if not req.hasSessionCookie() or force_login:
    # Redirect user to the login page
    var headers: HttpHeaders
    configPool.withConnection config:
      var return_to = "response_type=code&client_id=\"$#\"&redirect_uri=\"$#\"&scope=\"$#\"&force_login=$#&lang=en" % [client_id, req.getQueryParam("redirect_uri"), scopes.join(" "), $force_login]
      headers["Location"] = config.getStringOrDefault("web", "endpoint", "/") & "auth/sign_in/?return_to=" & return_to

    req.respond(
      303, headers, ""
    )
    return

  
proc oauthToken*(req: Request) =
  return
proc oauthRevoke*(req: Request) =
  return
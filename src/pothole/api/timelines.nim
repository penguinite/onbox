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
import quark/[follows, apps, oauth, auth_codes]

# From somewhere in Pothole
import pothole/[database, routeutils], pothole/private/apientities

# From somewhere in the standard library
import std/[json]
import std/strutils except isEmptyOrWhitespace, parseBool

# From nimble/other sources
import mummy

proc timelinesHome*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  
  # TODO: Implement pagination *properly*
  # If any of these are present, then just error out.
  for i in @["max_id", "since_id", "min_id"]:
    if req.isValidQueryParam(i):
      respJson("You're using a pagination feature and I honest to goodness WILL NOT IMPLEMENT IT NOW", 500)
  
  # Now we can begin actually implementing the API
  
  # Parse ?limit=x
  # If ?limit isn't present then default to 20 posts
  var limit = 20

  if req.isValidQueryParam("limit"):
    limit = parseInt(req.getQueryParam("limit"))

  if limit > 40:
    # MastoAPI docs sets a limit of 40.
    # So we will throw an error if it is over 40
    respJsonError("Limit cannot be over 40", 401)

  if not req.authHeaderExists():
    respJsonError("The access token is invalid (No auth header present)", 401)
      
  let token = req.getAuthHeader()
  var user = ""
  dbPool.withConnection db:
    # Check if the token exists in the db
    if not db.tokenExists(token):
      respJsonError("The access token is invalid (token not found in db)", 401)
        
    # Check if the token has a user attached
    if not db.tokenUsesCode(token):
      respJsonError("The access token is invalid (token isn't using an auth code)", 401)
        
    # Double-check the auth code used.
    if not db.authCodeValid(db.getTokenCode(token)):
      respJsonError("The access token is invalid (auth code used by token isn't valid)", 401)
    
    # Check if the client registered to the token
    # has a public oauth scope.
    if not db.hasScope(db.getTokenApp(token), "read:statuses"):
      respJsonError("The access token is invalid (scope read or read:statuses is missing) ", 401)

    user = db.getTokenUser(token)

  var result = newJArray()

  dbPool.withConnection db:
    for postId in db.getHomeTimeline(user, limit):
      result.elems.add(status(postId))
  req.respond(200, headers, $(result))

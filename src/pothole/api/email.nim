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
# api/email.nim:
## This module contains all the email-related API routes.

# From somewhere in Quark
import quark/[crypto, oauth, auth_codes, apps]

# From somewhere in Pothole
import pothole/[lib]
import pothole/[routeutils, database, conf]

# From somewhere in the standard library
import std/[json]

# From nimble/other sources
import mummy

proc emailConfirmation*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  if not req.authHeaderExists():
    respJsonError("This API requires an authenticated user", 401)
      
  let token = req.getAuthHeader()
  var user = ""
  dbPool.withConnection db:
    # Check if the token exists in the db
    if not db.tokenExists(token):
      respJsonError("This API requires an authenticated user", 401)
        
    # Check if the token has a user attached
    if not db.tokenUsesCode(token):
      respJsonError("This API requires an authenticated user", 401)
        
    # Double-check the auth code used.
    if not db.authCodeValid(db.getTokenCode(token)):
      respJsonError("This API requires an authenticated user", 401)
    
    
    

    user = db.getTokenUser(token)
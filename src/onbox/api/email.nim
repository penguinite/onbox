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
# onbox/api/email.nim:
## This module contains all the email-related API routes.

# From somewhere in Onbox
import onbox/[routes, conf, strextra, email]

# From somewhere in the standard library
import std/[json]

# From nimble/other sources
import mummy, waterpark/postgres,
       amicus/[oauth, email_codes, users]

proc emailConfirmation*(req: Request) =
  var token, user = ""
  try:
    token = req.verifyClientExists()

    # We can't use verifyClientUser()
    # Because we can't ignore email unverified users.
    dbPool.withConnection db:
      user = db.getTokenUser(token)
      if user == "":
        respJsonError("No user associated with token")
      
      # Frozen/Suspension check
      if db.userHasRole(user, -1):
        respJsonError("Your login is currently disabled")
      
      # Check if the user's account is pending verification
      if not db.userHasRole(user, 1):
        respJsonError("Your login is currently pending approval")
  except: return

  # Get email from client
  var email = ""

  case req.getContentType():
  of "application/x-www-form-urlencoded":
    email = formToJson(req.body)["email"].getStr("")
  of "application/json":
    email = parseJson(req.body)["email"].getStr("")
  else:
    respJsonError("Unknown Content-Type.")
  
  dbPool.withConnection db:
    # If the user has verified their email then leave
    if db.userVerified(user):
      respJsonError("This method is only available while the e-mail is awaiting confirmation")

    # Delete old email codes.
    db.deleteEmailCodeByUser(user)

    # Change email before sending new code
    if email != "":
      db.updateUserById(user, "email", email)

    configPool.withConnection config:
      config.sendEmailCode(db.createEmailCode(user), db.getUserEmail(user))
      
    req.respond(200, createHeaders("application/json"), "{}")
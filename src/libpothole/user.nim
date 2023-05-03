# Copyright © Leo Gavilieau 2022-2023
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# user.nim:
## This module contains various functions and procedures for handling User objects.
## The User object type has been moved here after commit 9f3077d
## Database-related procedures are in db.nim

# From Pothole
import lib, crypto

# From Nim's standard library
import std/strutils except isEmptyOrWhitespace

# A set of characters that you cannot use at all.
# this filters anything that doesn't make a valid email.
const unsafeHandleChars*: set[char] = {
  '!',' ','"', '#','$','%','&','\'',
  '(',')','*','+',',',';','<', '=','>',
  '?','[','\\',']','^','`','{','}','|',
  '~'
}

# A set of characters that you cannot use
# when registering a local user.
const localInvalidHandle*: set[char] = {'@',':','.'}

# User data type.
type 
  User* = ref object
    id*: string # An unique that represents the actual user
    handle*: string # A string containing the user's actual username 
    name*: string # A string containing the user's display name
    local*: bool # A boolean indicating if this user is from this instance 
    email*: string # A string containing the user's email
    bio*: string # A string containing the user's biography
    password*: string # A string to store a hashed + salted password 
    salt*: string # The actual salt with which to hash the password. 
    admin*: bool # A boolean indicating if the user is an admin.
    is_frozen*: bool #  A boolean indicating if the user is frozen/banned. 


proc sanitizeHandle*(handle: string): string =
  ## Checks a string against user.unsafeHandleChars
  ## This is mostly used for checking for valid emails and handles.
  if handle.isEmptyOrWhitespace():
    return "" 

  var oldhandle = toLowerAscii(handle)
  result = ""
  for ch in oldhandle:
    if ch notin unsafeHandleChars:
      result.add(ch)

  return result

proc newUser*(handle,password: string, local:bool = false): User =
  ## A procedure to create a new user with id, passwords salt and everything!
  ## It is highly recommended that you insert your own values
  result = User()

  # Create password and hash ONLY if user is local
  if local == true:

    if len(sanitizeHandle(handle)) < 0:
      error("Handle has only invalid characters.\nThis is probably a bug you should report.","user.newUser()")

    result.handle = sanitizeHandle(handle)
    result.local = true
  else:
    result.local = false
  
  # Every User in our database will have an ID.
  result.id = randomSafeString() # the 16 character default is good enough for IDs
  if local: 
    result.salt = randomString(18) # 16 is what NIST recommends. So what if we go slightly above?
    if isEmptyOrWhitespace(password):
      debug("Required field \"Password\" is empty!\nThis is probably a bug you should report to your server maintainer.", "user.newUser")
      
    result.password = hash(password, result.salt) # 160000 is what Pleroma/Akkoma uses and it's a little bit higher than what NIST recommends for this key-derivation function.
    
  result.handle = handle

  # A new user is typically not frozen
  # Even for external actors.
  result.is_frozen = false
  
  return result

proc escape*(olduser: User, skipChecks: bool = false): User =
  ## A procedure for escaping a User object
  ## skipChecks allows you to skip the essential handle and password checks.
  ## This is only used for potholectl.
  var user = olduser[] # Dereference early on for readability

  # We only need handle and password, the rest can be guessed or blank.
  if not skipChecks:
    if isEmptyOrWhitespace(user.handle) or isEmptyOrWhitespace(user.password):
      error("Missing required fields for adding users\nUser: " & $user,"user.escape")

  user.handle = sanitizeHandle(user.handle)
  user.email = sanitizeHandle(user.email)

  # Use handle as display name if display name doesnt exist or is blank
  if isEmptyOrWhitespace(user.name):
    user.name = user.handle

  # Now we loop over every field and escape it.
  # TODO: Look into using templates or macros to automatically
  #       generate the loop that escapes Users
  #       It could make this code a lot faster.
  for key,val in user.fieldPairs:
    when typeof(val) is bool:
      user.get(key) = val

    when typeof(val) is string:
      user.get(key) = escape(val)

  new(result); result[] = user # Re-reference it at the end.
  return 

proc unescape*(olduser: User): User =
  ## A procedure for unescaping a User object
  var user = olduser[]

  # TODO: Look into using templates or macros to automatically
  #       generate the loop that unescapes Users
  for key,val in user.fieldPairs:
    when typeof(val) is bool:
      user.get(key) = val

    when typeof(val) is string:
      user.get(key) = unescape(val,"","")
  
  new(result); result[] = user # Re-reference it at the end.
  return result

func `$`*(obj: User): string =
  ## Turns a User object into a human-readable string
  result.add("[")
  for key,val in obj[].fieldPairs:
    result.add("\"" & key & "\": \"" & $val & "\",")
  result = result[0 .. len(result) - 2]
  result.add("]")
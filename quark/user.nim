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
#
# user.nim:
## This module contains various functions and procedures for handling User objects.
## The User object type has been moved here after commit 9f3077d
## Database-related procedures are in db.nim

# From somewhere in Quark
import crypto, strextra
export KDF, KDFToInt, IntToKDF, StringToKDF

# From Nim's standard library
import std/strutils except isEmptyOrWhitespace, parseBool

# From somewhere else
import rng

# A set of characters that you cannot use at all.
# this filters anything that doesn't make a valid email.
const safeHandleChars*: set[char] = {
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
  'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
  'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7',
  '8', '9', '0', '.', '@', '-'
}

# A set of characters that you cannot use
# when registering a local user.
const localInvalidHandle*: set[char] = {'@',':','.'}

# User data type.
type 
  # What type of user, this is directly from ActivityStreams.
  UserType* = enum
    Person, Application, Organization, Group, Service

  User* = object
    id*: string # An unique that represents the actual user
    kind*: UserType # What type of User this is. (Used for outgoing Activities)
    handle*: string # A string containing the user's actual username 
    name*: string # A string containing the user's display name
    local*: bool # A boolean indicating if this user is from this instance 
    email*: string # A string containing the user's email
    bio*: string # A string containing the user's biography
    password*: string # A string to store a hashed + salted password 
    salt*: string # The actual salt with which to hash the password.
    kdf*: KDF # Key derivation function version
    admin*: bool # A boolean indicating if the user is an admin.
    moderator*: bool # A boolean indicating if the user is a moderator.
    is_frozen*: bool #  A boolean indicating if the user is frozen/banned. 
    is_approved*: bool # A boolean indicating if the user hs been approved by an administrator
    discoverable*: bool # A boolean indicating if the user is discoverable


func sanitizeHandle*(handle: string, charset: set[char] = safeHandleChars): string =
  ## Checks a string against user.unsafeHandleChars
  ## This is mostly used for checking for valid emails and handles.
  if handle.isEmptyOrWhitespace():
    return "" 

  var oldhandle = toLowerAscii(handle)
  result = ""
  for ch in oldhandle:
    if ch in charset:
      result.add(ch)

  return result

proc newUser*(handle: string, local: bool = false, password: string = ""): User =
  ## This procedure just creates a user and that's it
  ## We will fill out some basic details, like if you supply a password, name
  
  # First off let's do the things that are least likely to create an error in any way possible.
  result = User()
  result.id = randstr()
  
  result.salt = ""
  if local:
    result.salt = randstr(12)

  result.kdf = crypto.kdf # Always assume user is using latest KDF because why not?
  result.local = local
  result.admin = false # This is false by default.
  result.moderator = false # This is false by default.
  result.is_frozen = false # Always assume user isn't frozen.
  result.discoverable = true # This is the default.
  result.kind = Person # Even if its a group, service or application then it doesn't matter.

  # Sanitize handle before using it
  let newhandle = sanitizeHandle(handle)
  if newhandle.isEmptyOrWhitespace():
    return # We can't use the error template for some reason.
  result.handle = newhandle
    
  # Use handle as name
  result.name = newhandle
  
  result.password = ""
  if local and not isEmptyOrWhitespace(password):
    result.password = hash(password, result.salt)  

  # The only things remaining are email and bio which the program can guess based on its own context clues (Such as if the user is local)
  return result
  
func toUserType*(s: string): UserType =
  ## Converts a plain string into a UserType
  case s:
  of "Person": return Person
  of "Application": return Application
  of "Organization": return Organization
  of "Group": return Group
  of "Service": return Service
  else: return Person

func fromUserType*(t: UserType): string =
  ## Converts a UserType to string.
  result = case t:
    of Person: "Person"
    of Application: "Application"
    of Organization: "Organization"
    of Group: "Group"
    of Service: "Service"

func `$`*(t: UserType): string =
  return fromUserType(t)

proc isBot*(k: UserType): bool = 
  return k == Application

proc isGroup*(k: UserType): bool = 
  return k == Group

func `$`*(obj: User): string =
  ## Turns a User object into a human-readable string
  for key,val in obj.fieldPairs:
    result.add(key & ": \"" & $val & "\" \n")
  result = result[0 .. len(result) - 2]
  return result
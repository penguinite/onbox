# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later
#
# user.nim:
## Various procedures for handling User objects.
## The actual data types are stored in lib.nim
## And database-related procedures are stored in db.nim

# From Pothole
import lib, crypto

# From Nim's standard library
import std/strutils except isEmptyOrWhitespace

proc safeifyHandle*(handle: string): string =
  ## Checks a string against lib.unsafeHandleChars
  ## This is mostly used for checking for valid emails and handles.
  for ch in handle:
    if ch notin unsafeHandleChars:
      result.add(ch)

proc newUser*(handle,password: string, local:bool = false): User =
  ## A procedure to create a new user with id, passwords salt and everything!
  ## It is highly recommended that you insert your own values
  
  var newuser = User()

  # Create password and hash ONLY if user is local
  if local == true:

    if len(safeifyHandle(handle)) < 0:
      error("Handle has only invalid characters.","user.newUser()")

    newuser.handle = safeifyHandle(handle)
    newuser.local = true
  else:
    newuser.local = false
  
  # Every User in our database will have an ID.
  newuser.id = randomString() # the 16 character default is good enough for IDs
  if local: 
    newuser.salt = randomString(18) # 32 characters is double what NIST recommends for salt lengths.
    if isEmptyOrWhitespace(password):
      error("Missing critical field \"Password\"\nProvided: " & handle & ", " & password, "data.newUser")

    newuser.password = hash(password, newuser.salt) # 160000 is what Pleroma/Akkoma uses and it's a little bit higher than what NIST recommends for this key-derivation function.
    
  newuser.handle = handle

  # A new user is typically not frozen
  # Even for external actors.
  newuser.is_frozen = false
  
  return newuser

proc escape*(olduser: User): User =
  ## A procedure for escaping a User object
  var user = olduser[] # Dereference early on for readability

  # We only need handle and password, the rest can be guessed or blank.
  if isEmptyOrWhitespace(user.handle) or isEmptyOrWhitespace(user.password):
    error("Missing required fields for adding users\nUser: " & $user,"data.escape(User)")

  user.handle = safeifyHandle(toLowerAscii(user.handle))
  user.email = safeifyHandle(toLowerAscii(user.email))

  # Use handle as display name if display name doesnt exist or is blank
  if isEmptyOrWhitespace(user.name):
    user.name = user.handle

  for key,val in user.fieldPairs:
    when typeof(val) is bool:
      user.get(key) = val

    when typeof(val) is string:
      user.get(key) = escape(val,"","")

  new(result); result[] = user # Re-reference it at the end.
  return 

proc unescape*(olduser: User): User =
  ## A procedure for unescaping a User object
  var user = olduser[]

  for key,val in user.fieldPairs:
    when typeof(val) is bool:
      user.get(key) = val

    when typeof(val) is string:
      user.get(key) = unescape(val,"","")
  
  new(result); result[] = user # Re-reference it at the end.
  return result

func `$`*(obj: User): string =
  ## Turns a User object into a human-readable string
  result.add("(")
  for key,val in obj[].fieldPairs:
    result.add("\"" & key & "\": \"" & $val & "\",")
  result = result[0 .. len(result) - 2]
  result.add(")")
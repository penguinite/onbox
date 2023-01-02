# Copyright © Louie Quartz 2022
# Licensed under AGPL version 3 or later
#
# data.nim:
## Functions for handling Pothole-specific data types.
## The actual data types are stored in lib.nim

# From Pothole
import lib
import crypto

# From Nim's standard library
import std/strutils

## User data type, which represents actual users in the database.
## Here are all of the fields in a user objects, with an explanation:
runnableExamples:
  # -    id: string     =   An OID that represents the actual user (Db: blob primary key)
  # -    handle: string =   A string containing the user's actual username (Db: varchar unique not null)
  # -    name: string   =   A string containing the user's display name (Db: varchar)
  # -    local: bool    =   A boolean indicating if this user is from this instance (Db: boolean)
  # -    email: string  =   A string containing the user's email (Db: varchar)
  # -    bio: string    =   A string containing the user's biography (Db: varchar)
  # -    password:string=   A string to store a hashed + salted password (Db: varchar not null)
  # -    salt: string   =   The actual salt with which to hash the password. (Db: varchar not null)
  # -    is_frozen:bool =   A boolen indicating if the user is frozen/banned.
  discard

# Various helper procedures related to Users and Posts
# db.nim contains the actual user-creation procedures

proc newUser*(handle,password: string, local:bool = false): User =
  ## A procedure to create a new user with id, passwords salt and everything!
  ## The user from this procedure is not validaed or escaped, make sure to run
  ## user.escape() or just db.addUser() do it for you!
  if isEmptyOrWhitespace(handle):
    error("Missing critical fields!\nProvided: " & handle & ", " & password)
  var newuser: User;

  # Create password and hash ONLY if user is local
  if local == true:
    for x in localInvalidHandle:
      newuser.handle = newuser.handle.replace($x,"")
    newuser.local = true
  else:
    newuser.local = false
  
  # Every User in our database will have an ID.
  newuser.id = randomString() # the 16 character default is good enough for IDs
  if local: 
    newuser.salt = randomString(18) # 32 characters is double what NIST recommends for salt lengths.
    newuser.password = hash(password, newuser.salt) # 160000 is what Pleroma/Akkoma uses and it's a little bit higher than what NIST recommends for this key-derivation function.
    
  newuser.handle = handle
  
  return newuser

# A function remove any unsafe characters
proc safeifyHandle*(handle: string): string =
  var newhandle = handle;
  var i: int = len(newhandle) - 1
  for x in 0 .. i:
    if newhandle[x] in unsafeHandleChars:
      newhandle = newhandle.replace($newhandle[x],"")
      i = len(newhandle) - 1
  return newhandle

proc escape*(user: var User): User =
  ## This procedure validates all fields and escapes them so it can
  ## be stored in a database! The opposite of this function is unescape, which is meant to take a fresh user out of the database to be unescaped and processed by the app.

  # We only need handle and password, the rest can be guessed or blank.
  if isEmptyOrWhitespace(user.handle) or isEmptyOrWhitespace(user.password):
    error("Missing required fields for adding users\nUser: " & $user,"data.escape(User)")

  # Handle and email need their own special rules
  user.handle = safeifyHandle(toLowerAscii(user.handle))
  user.email = safeifyHandle(toLowerAscii(user.email))

  # Use handle as display name if display name doesnt exist or is blank
  if isEmptyOrWhitespace(user.name):
    user.name = user.handle

  # Loop over all fields in user and escape them.
  # This should be done last thing. 
  for key, value in user.fieldPairs:
    when user.get(key) is bool:
      user.get(key) = value

    when user.get(key) is string:
      # Store string as is, just escape it though.
      user.get(key) = escape(value)

  return user


proc escape*(user: User): User =
  ## A helper function that initializes a new User object for you!
  var newuser: User = user;
  return newuser.escape()

proc unescape*(user: var User): User =
   # Loop over all fields in user and escape them.
  # This should be done last thing. 
  for key, value in user.fieldPairs:
    when user.get(key) is bool:
      user.get(key) = value

    when user.get(key) is string:
      # Store string as is, just escape it though.
      user.get(key) = unescape(value,"","")
      
  return user

proc unescape*(user: User): User =
  ## A helper function that initializes a new User object for you!
  var newuser: User = user;
  return newuser.unescape()

proc newPost*(sender,replyto,content: string, recipients: seq[string], local: bool = false): Post =
  var post: Post;
  if isEmptyOrWhitespace(sender) or isEmptyOrWhitespace(content):
    error("Missing critical fields for post.","data.newPost")

  # Generate post id
  post.id = randomString()
  
  # Just do this stuff...
  post.sender = sender
  post.recipients = recipients

  post


  return post

proc escape*(post: var Post): Post =

  return post
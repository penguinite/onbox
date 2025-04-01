# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
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
# db/users.nim:
## This module contains various functions and procedures for handling users.

# From Quark
import ../[shared, strextra, crypto], private/utils

# From the standard library
import std/[strutils, tables]

# From elsewhere
import rng, db_connector/db_postgres

# Permitted character set.
# this filters anything that doesn't make a valid email.
const safeHandleChars*: set[char] = {
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k',
  'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
  'w', 'x', 'y', 'z', '1', '2', '3', '4', '5', '6', '7',
  '8', '9', '0', '.', '@', '-',
}

func sanitizeHandle*(handle: string, charset: set[char] = safeHandleChars): string =
  ## Checks a string against user.unsafeHandleChars
  ## This is mostly used for checking for valid handles.
  for ch in toLowerAscii(handle):
    if ch in charset:
      result.add(ch)

proc newUser*(handle: string, local = true, password = ""): User =
  result.id = rng.uuidv4()
  result.handle = sanitizeHandle(handle)
  result.local = local

  if local:
    result.domain = ""
    result.salt = rng.randstr(20)
    if password != "":
      result.password = hash(password, result.salt)
  
  # Set some defaults
  result.roles = @[]
  result.discoverable = false
  result.email_verified = false

proc addUser*(db: DbConn, user: User) = 
  ## Add a user to the database
  db.exec(
    sql"INSERT INTO users VALUES (?,?,?,?,?,?,?,?,?,?,?,?);",
    user.id, !$(user.kdf), !$(user.roles), $(user.discoverable),
    $(user.email_verified), user.handle, user.domain, user.name,
    user.email, user.bio, user.password, user.salt
  )

proc getAdmins*(db: DbConn): seq[string] = 
  ## A procedure that returns the IDs of all administrators.
  # TODO: Same problem as pothole/db/boosts.getBoostsQuick() where we have an extra for loop.
  for row in db.getAllRows(sql"SELECT id FROM users WHERE roles @> '{3}';"):
    result.add(row[0])
  
proc getTotalLocalUsers*(db: DbConn): int =
  ## A procedure to get the total number of local users.
  len(db.getAllRows(sql"SELECT 0 FROM users WHERE domain = '';"))

proc getDomains*(db: DbConn): CountTable[string] =
  ## A procedure to get the all of the domains known by this server in a CountTable
  for handle in db.getAllRows(sql"SELECT domain FROM users WHERE domain != '';"):
    result.inc(handle[0])

proc getTotalDomains*(db: DbConn): int =
  len(db.getAllRows(sql"SELECT DISTINCT ON (domain) FROM users WHERE domain != '';"))

proc userIdExists*(db: DbConn, id:string): bool =
  ## A procedure to check if a user exists by id
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM users WHERE id = ?);", id
  )[0] == "t"

proc userHandleExists*(db: DbConn, handle:string, domain = ""): bool =
  ## A procedure to check if a user exists by handle
  ## This procedure does sanitize and escape handles by default
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM users WHERE handle = ? AND domain = ?);", handle, domain
  )[0] == "t"

proc userEmailExists*(db: DbConn, email: string): bool =
  ## Checks if a user with a specific email exists.
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM users WHERE email = ?);", email
  )[0] == "t"

proc getUserIdByEmail*(db: DbConn, email: string): string =
  ## Retrieves the user id by using the email associated with the user
  db.getRow(sql"SELECT id FROM users WHERE email = ?;", email)[0]

proc getUserSalt*(db: DbConn, user_id: string): string = 
  db.getRow(sql"SELECT salt FROM users WHERE id = ?;", user_id)[0]

proc getUserPass*(db: DbConn, user_id: string): string = 
  db.getRow(sql"SELECT password FROM users WHERE id = ?;", user_id)[0]

proc isAdmin*(db: DbConn, user_id: string): bool =
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM users WHERE roles @> '{3}' AND id = ?);",
    user_id
  )[0] == "t"
  
proc isModerator*(db: DbConn, user_id: string): bool =
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM users WHERE roles @> '{2}' AND id = ?);",
    user_id
  )[0] == "t"
  
proc getUserKDF*(db: DbConn, user_id: string): KDF =
  toKDF(db.getRow(sql"SELECT kdf FROM users WHERE id = ?;", user_id)[0])

proc constructUserFromRow*(row: Row): User =
  ## A procedure that takes a database Row (From the users table)
  ## And turns it into a User object, ready for processing.
  ## It unescapes users by default

  # This looks ugly, I know, I had to wrap it with
  # two specific functions but we don't have to re-write this
  # even if we add new things to the User object. EXCEPT!
  # if we introduce new data types to the User object
  var i: int = -1;

  for key,value in result.fieldPairs:
    inc(i)
    # If its string, add it surrounding quotes
    # Otherwise add it whole
    when result.get(key) is bool:
      result.get(key) = (row[i] == "t")
    when result.get(key) is string:
      result.get(key) = row[i]
    when result.get(key) is int:
      result.get(key) = parseInt(row[i])
    when result.get(key) is seq[int]:
      result.get(key) = toIntSeq(row[i])
    when result.get(key) is KDF:
      result.get(key) = toKdf(row[i])

proc userFrozen*(db: DbConn, user_id: string): bool =
  ## Returns whether or not a user is frozen. ID must be a user id.
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM users WHERE roles @> '{-1}' AND id = ?);",
    user_id
  )[0] == "t"

proc userVerified*(db: DbConn, user_id: string): bool =
  ## Returns whether or not a user has a verifd email address. ID must be a user id.
  db.getRow(sql"SELECT email_verified FROM users WHERE id = ?;", user_id)[0] == "t"

proc userApproved*(db: DbConn, user_id: string): bool =
  ## Returns whether or not a user is approved. ID must be a user id.
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM users WHERE roles @> '{1}' AND id = ?);",
    user_id
  )[0] == "t"

proc getFirstAdmin*(db: DbConn): string =
  db.getRow(sql"SELECT id FROM users WHERE roles @> '{3}' LIMIT 1;")[0]

proc adminAccountExists*(db: DbConn): bool =
  db.getRow(sql"SELECT EXISTS(SELECT 0 FROM users WHERE roles @> '{3}');")[0] == "t"

proc getUserBio*(db: DbConn, id: string): string = 
  db.getRow(sql"SELECT bio FROM users WHERE id = ?;", id)[0]

proc getUserById*(db: DbConn, id: string): User =
  ## Retrieve a user from the database using their id
  ## This procedure returns a fully unescaped user, you do not need to do anything to it.
  ## This procedure expects a regular ID, it will sanitize and escape it by default.
  constructUserFromRow(db.getRow(sql"SELECT * FROM users WHERE id = ?;", id))

proc getUserByHandle*(db: DbConn, handle: string): User =
  ## Retrieve a user from the database using their handle
  ## This procedure returns a fully unescaped user, you do not need to do anything to it.
  ## This procedure expects a regular handle, it will sanitize and escape it by default.
  constructUserFromRow(db.getRow(sql"SELECT * FROM users WHERE handle = ?;", handle))

proc updateUserByHandle*(db: DbConn, handle: string, column, value: string) =
  ## A procedure to update any user (The user is identified by their handle)
  ## The *only* parameter that is sanitized is the handle, the value has to be sanitized by your user program!
  ## Or else you will be liable to truly awful security attacks!
  ## For guidance, look at the sanitizeHandle() procedure in user.nim or the escape() procedure in the strutils module
  db.exec(sql("UPDATE users SET " & column & " = ? WHERE handle = ?;"), value, handle)
  
proc updateUserById*(db: DbConn, id, column, value: string) = 
  ## A procedure to update any user (The user is identified by their ID)
  db.exec(sql("UPDATE users SET " & column & " = ? WHERE id = ?;"), value, id)

proc getIdFromHandle*(db: DbConn, handle: string, domain = ""): string =
  ## A function to convert a user handle to an id.
  ## This procedure expects a regular handle, it will sanitize and escape it by default.
  db.getRow(sql"SELECT id FROM users WHERE handle = ? and domain = ?;", handle, domain)[0]

proc getHandleFromId*(db: DbConn, id: string): string =
  ## A function to convert a  id to a handle.
  ## This procedure expects a regular ID, it will sanitize and escape it by default.
  db.getRow(sql"SELECT handle FROM users WHERE id = ?;", id)[0]

proc deleteUser*(db: DbConn, id: string) =
  ## Deletes a user and marks their visible content as null.
  ## You don't need to do anything before running this proc.
  # TODO: This is just too much all at once... But it'll be alright... right?
  # Delete stuff no one will ever see
  db.exec(sql"DELETE FROM auth_codes WHERE uid = ?;", id)
  db.exec(sql"DELETE FROM email_codes WHERE uid = ?;", id)
  db.exec(sql"DELETE FROM oauth_tokens WHERE uid = ?;", id)
  db.exec(sql"DELETE FROM tag_follows WHERE follower = ?;", id)
  db.exec(sql"DELETE FROM logins WHERE uid = ?;", id)
  db.exec(sql"DELETE FROM fields WHERE uid = ?;", id)

  # For the stuff we suspect to be heavy, we will just
  # mark the user's data as "null" and it'll all be deleted at some point later.
  db.exec(sql"UPDATE user_follows SET follower = 'null' WHERE follower = ?;", id)
  db.exec(sql"UPDATE user_follows SET following = 'null' WHERE following = ?;", id)
  db.exec(sql"UPDATE reactions SET uid = 'null' WHERE uid = ?;", id)
  db.exec(sql"UPDATE boosts SET uid = 'null' WHERE uid = ?;", id)
  db.exec(sql"UPDATE bookmarks SET uid = 'null' WHERE uid = ?;", id)
  db.exec(sql"UPDATE posts SET sender = 'null' WHERE sender = ?;", id)

  # Finally delete the stuff we don't need
  db.exec(sql"DELETE FROM users WHERE id = ?;", id)
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
#
# quark/db/follows.nim:
## This module contains all database logic for handling followers, following and so on.

import quark/private/database
import quark/users

proc getFollowersQuick*(db: DbConn, user: string): seq[string] =
  ## Returns a set of handles that follow a specific user
  for row in db.getAllRows(sql"SELECT follower FROM follows WHERE following = ? AND approved = true;", user):
    result.add(db.getHandleFromId(row[0]))
  return result

proc getFollowingQuick*(db: DbConn, user: string): seq[string] =
  ## Returns a set of handles that a specific user follows
  for row in db.getAllRows(sql"SELECT following FROM follows WHERE follower = ? AND approved = true;", user):
    result.add(db.getHandleFromId(row[0]))
  return result

proc getFollowers*(db: DbConn, user: string): seq[User] =
  ## Returns a set of User objects that follow a specific usr
  for row in db.getAllRows(sql"SELECT follower FROM follows WHERE following = ? AND approved = true;", user):
    result.add(db.getUserById(row[0]))
  return result

proc getFollowing*(db: DbConn, user: string): seq[User] =
  ## Returns a set of User objects that a specific user follows
  for row in db.getAllRows(sql"SELECT following FROM follows WHERE follower = ? AND approved = true;", user):
    result.add(db.getUserById(row[0]))
  return result

proc getFollowersCount*(db: DbConn, user: string): int =
  ## Returns how many people follow this user in a number
  return len(db.getAllRows(sql"SELECT approved FROM follows WHERE following = ? AND approved = true;", user))

proc getFollowingCount*(db: DbConn, user: string): int =
  ## Returns how many people this user follows in a number
  return len(db.getAllRows(sql"SELECT approved FROM follows WHERE follower = ? AND approved = true;", user))

proc getFollowReqCount*(db: DbConn, user: string): int =
  ## Returns how many pending follow requests a user has.
  return len(db.getAllRows(sql"SELECT approved FROM follows WHERE following = ? AND approved = false;", user))
  
type
  FollowStatus* = enum
    NoFollowRequest, PendingFollowRequest, AcceptedFollowRequest

proc getFollowStatus*(db: DbConn, follower, following: string): FollowStatus =
  let row = db.getRow(sql"SELECT approved FROM follows WHERE follower = ? AND following = ?;", follower, following)

  # It's small details like these that break the database logic.
  # You'd expect getRow() to return booleans like this: "true" or "false"
  # But no, it does "t" or "f" which, std/strutil's parseBool() can't handle
  # Thankfully, i've been through this rigamarole before,
  # so i already knew boolean handling was garbage
  if row == @["f"]: return PendingFollowRequest
  if row == @["t"]: return AcceptedFollowRequest
  return NoFollowRequest

proc followUser*(db: DbConn, follower, following: string, approved: bool = true) =
  ## Follows a user
  if not db.userIdExists(follower) or not db.userIdExists(following):
    return # Since users don't exist, we just leave.

  if db.getFollowStatus(follower, following) != NoFollowRequest:
    # Follow request already exists and is either pending or accepted.
    # In that case, just return.
    return
  
  db.exec(
    sql"INSERT INTO follows VALUES (?, ?, ?)",
    follower, following, $approved
  )

proc unfollowUser*(db: DbConn, follower, following: string) =
  ## Unfollows a user
  if not db.userIdExists(follower) or not db.userIdExists(following):
    return # Since users don't exist, we just leave.

  db.exec(
    sql"DELETE FROM follows WHERE follower = ? AND following = ?;",
    follower, following
  )

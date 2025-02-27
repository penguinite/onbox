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
# db/follows.nim:
## This module contains all database logic for handling followers, following and so on.
## This module handles mostly following users, you can follow tags in the tag.nim module
import ../shared, db_connector/db_postgres

proc getFollowers*(db: DbConn, user: string): seq[string] =
  ## Returns a set of User IDs followed by a specific user.
  ## 
  ## Note: This only returns approved requests.
  # TODO: Same problem as pothole/db/boosts.getBoostsQuick() where we have an extra for loop.
  for row in db.getAllRows(sql"SELECT follower FROM user_follows WHERE following = ? AND approved = true;", user):
    result.add(row[0])

proc getFollowing*(db: DbConn, user: string): seq[string] =
  ## Returns a set of User IDs that a specific user follows.
  ## 
  ## Note: This only returns approved requests.
  # TODO: Same problem as pothole/db/boosts.getBoostsQuick() where we have an extra for loop.
  for row in db.getAllRows(sql"SELECT following FROM user_follows WHERE follower = ? AND approved = true;", user):
    result.add(row[0])

proc getFollowing*(db: DbConn, user: string, limit = 20): seq[string] =
  ## Returns a set of User IDs that a specific user follows.
  ## This procedure has a limit of 20 by default´
  ## 
  ## Note: This only returns approved requests.
  # TODO: Same problem as pothole/db/boosts.getBoostsQuick() where we have an extra for loop.
  for row in db.getAllRows(sql"SELECT following FROM user_follows WHERE follower = ? AND approved = true LIMIT ?;", user, $limit):
    result.add(row[0])

proc getFollowersCount*(db: DbConn, user: string): int =
  ## Returns how many people follow this user in a number
  len(db.getAllRows(sql"SELECT 0 FROM user_follows WHERE following = ? AND approved = true;", user))

proc getFollowingCount*(db: DbConn, user: string): int =
  ## Returns how many people this user follows in a number
  len(db.getAllRows(sql"SELECT 0 FROM user_follows WHERE follower = ? AND approved = true;", user))

proc getFollowReqCount*(db: DbConn, user: string): int =
  ## Returns how many pending follow requests a user has.
  len(db.getAllRows(sql"SELECT 0 FROM user_follows WHERE following = ? AND approved = false;", user))

proc getFollowStatus*(db: DbConn, follower, following: string): FollowStatus =
  ## Get the status of user A following user B.
  ## 
  ## This can be one of three things:
  ##    1. PendingFollowRequest: the `follower` (user A) has sent a follow request.
  ##       the `following` (user B) hasn't accepted it yet
  ## 
  ##    2. AcceptedFollowRequest: the `follower` (user A) has sent a follow request to
  ##       the `following` (user B) and they've accepted it.
  ## 
  ##    3. NoFollowRequest: the `follower` (user A) either hasn't sent a follow request
  ##       or the `following` (user B) has denied it previously.
  
  # It's small details like these that break the database logic.
  # You'd expect getRow() to return booleans like this: "true" or "false"
  # But no, it does "t" or "f" which, std/strutil's parseBool() can't handle
  # Thankfully, i've been through this rigamarole before,
  # so i already knew boolean handling was garbage
  result = case db.getRow(
      sql"SELECT approved FROM user_follows WHERE follower = ? AND following = ?;",
      follower,
      following
    )[0]:
    of "t": PendingFollowRequest
    of "f": AcceptedFollowRequest
    else: NoFollowRequest

proc followUser*(db: DbConn, follower, following: string, approved = true) =
  ## Follows a user, every string here has to be an ID.
  ## Remember to check if the users exist and if the follower has already sent a request earlier.
  db.exec(sql"INSERT INTO user_follows VALUES (?, ?, ?)", follower, following, $approved)

proc unfollowUser*(db: DbConn, follower, following: string) =
  ## Unfollows a user, every string here has to be an ID.
  db.exec(sql"DELETE FROM user_follows WHERE follower = ? AND following = ?;",follower, following)
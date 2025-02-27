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
# db/tag.nim:
## This module contains all database logic for handling hashtags!
## Including creation, retrieval, checking, updating and deletion
import ../strextra, std/times, db_connector/db_postgres

proc tagExists*(db: DbConn, tag: string): bool =
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM tag WHERE name = ?);", tag
  )[0] == "t"

proc getTagUrl*(db: DbConn, tag: string): string =
  db.getRow(sql"SELECT url FROM tag WHERE name = ?;", tag)[0]

proc userFollowsTag*(db: DbConn, user, tag: string): bool =
  ## Returns true if a user (supplied by ID) follows a hashtag
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM tag_follows WHERE follower = ? AND following = ?);",
    user, tag
  )[0] == "t"

proc getTagsFollowedByUser*(db: DbConn, user: string, limit = 100): seq[string] =
  # TODO: Same problem as pothole/db/boosts.getBoostsQuick() where we have an extra for loop.
  for i in db.getAllRows(sql"SELECT following FROM tag_follows WHERE follower = ? LIMIT ?;", user, $(limit)):
    result.add(i[0])

proc followTag*(db: DbConn, user, tag: string) =
  db.exec(
    sql"INSERT INTO tag_follows VALUES (?,?);",
    user, tag
  )

proc unfollowTag*(db: DbConn, user, tag: string) =
  db.exec(
    sql"DELETE FROM tag_follows WHERE follower = ? AND following = ?;",
    user, tag
  )

proc createTag*(
    db: DbConn, name: string, url = "", desc = "",
    trendable = true, usable = true, requires_review = false, system = false
  ) =
  ## Creates a new tag object in the database
  db.exec(
    sql"INSERT INTO tag VALUES (?,?,?,?,?,?,?);",
    trendable, usable, requires_review, system,
    name, url, desc
  )

proc postHasTag*(db: DbConn, post, tag: string): bool =
  ## Check if a post has a tag.
  db.getRow(
    sql"SELECT EXISTS(SELECT 0 FROM posts WHERE id = ? AND tags @> ?);",
    post, !$([tag])
  )[0] == "t"

# For the next three procs
# Given that this API is called on startup by a staggering number of clients,
# The top priority was to increase performance as much as possible.
# And I believe I did the right thing here but in the future, we must re-evaluate.

proc getTagUsagePostNum*(db: DbConn, tag: string, days = 2): seq[int] =
  ## Returns the number of posts using a tag in the past couple X days.
  # Game plan:
  # Select all the posts that were last published in the past number of days
  # And that have the specific tag required.
  #
  # TODO: This is a bit ugly... Could we optimize it?
  # Still, way way better than the old code!
  for i in countup(0,days - 1):
    result.add len(db.getAllRows(
      sql"SELECT 0 FROM posts WHERE tags @> ? AND created = ?;",
      !$[tag], getDateStr(now().utc - i.days)
    ))

proc getTagUsageUserNum*(db: DbConn, tag: string, days = 2): seq[int] =
  ## Returns the number of accounts using a tag in the past couple X days
  # Game plan:
  # Select all the users who have been last writing posts
  # that included a certain tag in the past number of days.
  #
  # TODO: Whew, this is a bit uglier than getTagUsagePostNum()
  # Jesus...
  for i in countup(0,days - 1):
    result.add len(db.getAllRows(
      sql"SELECT DISTINCT ON (sender) 0 FROM posts WHERE tags @> ? AND use_date = ?;",
      !$[tag], getDateStr(now().utc - i.days)
    ))

proc getPostTags*(db: DbConn, post: string): seq[string] =
  toStrSeq(db.getRow(sql"SELECT tags FROM posts WHERE id = ?;", post)[0])

proc getTagUsageDays*(days = 2): seq[int64] =
  ## Used only for the Tag ApiEntity
  for i in countup(0,days - 1):
    result.add(toUnix(toTime(now().utc - i.days)))

# Test suite:
#[
# TODO: This code uses the old newPost proc, maybe make sure to migrate it properly to the new one? (Previously named newPostX)

when isMainModule:
  import quark/[db, users, posts]
  import pothole/[conf, database]
  var config = setup(getConfigFilename())
  var deebee = setup(
    config.getDbName(),
    config.getDbUser(),
    config.getDbHost(),
    config.getDbPass()
  )

  var
    userA = newUser("a", true, "")
    userB = newUser("b", true, "")
    postA = newPost(userA.id, @[text("Badabing badaboom!"), hashtag("hi")])
    postB = newPost(userA.id, @[text("Badabing badaboom 2!"), hashtag("hi")])
    postC = newPost(userB.id, @[text("Badabing badaboom 3?"), hashtag("hi")])

  deebee.addUser(userA)
  deebee.addUser(userB)
  deebee.addPost(postA)
  deebee.addPost(postB)
  deebee.addPost(postC)
  

  if not deebee.tagExists("hi"):
    deebee.createTag("hi")
  echo deebee.getTagUsagePostNum("hi")
  echo deebee.getTagUsageUserNum("hi")
]#
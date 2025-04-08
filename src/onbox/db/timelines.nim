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
#
# onbox/db/timelines.nim:
## This module handles timelines.

import tag, follows, ../strextra
import std/[sequtils, times]
import db_connector/db_postgres

proc getHomeTimeline*(db: DbConn, user: string, limit: var int = 20): seq[string] =
  ## Returns a list of IDs to posts sent by users that `user` follows or in hashtags that `user` follows.
  # Let's see who this user follows 
  var
    following = db.getFollowing(user, limit)
    followingTags = db.getTagsFollowedByUser(user, limit)
  
  # First we check to see if the limit is realistic
  # (ie. do we have enough posts to fill it)
  # If not then we just reset the limit to something sane.

  # Note: Due to a circular dependency on posts, we have to use this
  # Instead of calling getNumTotalPosts()
  let t_limit = len(db.getAllRows(sql"SELECT 0 FROM posts;"))
  if limit > t_limit:
    limit = t_limit

  # We will start by fetching X number of posts from the db
  # (where X is the limit, oh and the order is chronological, according to *creation* date.)
  # And then checking if its creator was followed or if it has a hashtag we follow.
  #
  # This seemed like the best solution at the time given the circumstances
  # But if it isn't then whoopsie! We will make another one!
  # TODO: Help.
  var
    last_date = now().utc
    flag = false
  while len(result) < limit and flag == false:
    for row in db.getAllRows(sql"SELECT id,sender,created FROM posts WHERE date(created) >= ? ORDER BY created ASC LIMIT ?", !$(last_date), $limit):
      if row[1] in following or row[1] == user:
        result.add row[0]
        continue
      
      let tags = db.getPostTags(row[0])
      for tag in followingTags:
        if tag in tags:
          result.add row[0]
          continue
    flag = true
    result = result.deduplicate()
  
  # TODO: This does not include posts that have boosts... Too bad!
  return result

proc getTagTimeline*(db: DbConn, tag: string, limit: var int = 20, local = true, remote = true): seq[string] =
  ## Returns a list of IDs to posts in a hashtag.
  ## TODO: Implement.
  return result


## Test suite!
#[

# TODO: This code is quite old, migrate it

when isMainModule:
  import onbox/db/[db, users, posts]
  import onbox/[conf, database]
  var config = setup(getConfigFilename())
  var deebee = setup(
    config.getDbName(),
    config.getDbUser(),
    config.getDbHost(),
    config.getDbPass()
  )

  var
    userA = newUser("a", true, "a") # Home timeline user
    niceGuy = newUser("nice", true, "") # Followed user, followed hashtag
    rudeGuy = newUser("rude", true, "") # Followed user, unfollowed hashtag

    postB = newPost(niceGuy.id, @[text("Badabing badaboom!"), hashtag("followed")]) # Followed user, followed hashtag
    postC = newPost(niceGuy.id, @[text("Badabing badaboom Electric boogaloo!"), hashtag("unfollowed")]) # Followed user, unfollowed hashtag
    postD = newPost(rudeGuy.id, @[text("Badabing badaboom Electric Electric boogaloo!"), hashtag("followed")]) # Unfollowed user, followed hashtag
    postE = newPost(rudeGuy.id, @[text("Badabing badaboom Electric Electric II Boogaloo??"), hashtag("unfollowed")]) # Unfollowed user, unfollowed hashtag

  deebee.addUser(userA)
  deebee.addUser(niceGuy)
  deebee.addUser(rudeGuy)
  deebee.followUser(userA.id, niceGuy.id)
  if not deebee.tagExists("followed"):
    deebee.createTag("followed")
  deebee.followTag("followed", userA.id)

  deebee.addPost(postB)
  deebee.addPost(postC)
  deebee.addPost(postD)
  deebee.addPost(postE)

  var limit = 4
  let home = deebee.getHomeTimeline(userA.id, limit)
  echo home
  for post in home:
    if post == postB.id:
      echo "found: Followed user, followed hashtag"
    elif post == postC.id:
      echo "found: Followed user, unfollowed hashtag"
    elif post == postD.id:
      echo "found: Unfollowed user, followed hashtag"
    elif post == postE.id:
      echo "found: Unfollowed user, unfollowed hashtag"

  assert postB.id in home, "Failed test: Followed user, followed hashtag"
  assert postC.id in home, "Failed test: Followed user, unfollowed hashtag"
  assert postD.id in home, "Failed test: Unfollowed user, followed hashtag"
  assert postE.id notin home, "Failed test: Unfollowed user, unfollowed hashtag"
]#
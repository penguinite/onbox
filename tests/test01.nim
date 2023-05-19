## Just reporting some stuff.

import libpothole/[lib, db, user, post]

echo("Version reported: ", version)
echo("Database engine: ", dbEngine)

discard db.init("main.db")

import strutils

when not defined(iHaveMyOwnStuffThanks):
  echo "Adding fake users"
  for x in getFakeUsers():
    discard db.addUser(escape(x))

  echo "Adding fake posts"
  for x in getFakePosts():
    discard db.addPost(escape(x))

for post in db.getLocalPosts():
  echo($post) 
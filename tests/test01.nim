## Just reporting some stuff.

import libpothole/[lib, db, user, post]

echo("Version reported: ", version)
echo("Database engine: ", dbEngine)

discard db.init("main.db")

import strutils

when defined(addTestStuff):
  for x in getFakeUsers():
    x.admin = true
    x.local = true
    discard db.addUser(escape(x))
  for x in getFakePosts():
    discard db.addPost(escape(x))

for post in db.getLocalPosts():
  echo($post) 
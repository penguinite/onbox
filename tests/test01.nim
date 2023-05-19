echo "Test 01 - Database Operations"

import libpothole/[lib, db, user, post, debug]

echo("Version reported: ", version)
echo("Database engine: ", dbEngine)

echo "Initializing database"

when dbEngine == "sqlite":
  if not db.init("main.db"):
    error "Database failed to initialize","test02.startup"

when not defined(iHaveMyOwnStuffThanks):
  echo "Adding fake users"
  for x in getFakeUsers():
    discard db.addUser(escape(x))

  echo "Adding fake posts"
  for x in getFakePosts():
    discard db.addPost(escape(x))


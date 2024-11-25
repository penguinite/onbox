discard """
  action: "run"
  batchable: true
  joinable: true
  
  #valgrind: false   # Can use Valgrind to check for memory leaks, or not (Linux 64Bit only).
  
  # Targets to run the test into (c, cpp, objc, js). Defaults to c.
  targets: "cpp"
  
  # flags with which to run the test, delimited by `;`
  matrix: "-d:release ; -d:debug"

"""

import pothole/[conf, database]
import quark/[post]
import debug


# A basic config so that we don't error out.
var exampleConfig = ""

for section, preKey in requiredConfigOptions.pairs:
  exampleConfig.add("\n[" & section & "]\n")
  for key in preKey:
    exampleConfig.add(key & "=\"Test value\"\n")

exampleConfig.add """
[db]
host="127.0.0.1:5432"
name="pothole"
user="pothole"
password="SOMETHING_SECRET"
"""

let
  config = setupInput(exampleConfig)
  db = setup(
    config.getDbName(),
    config.getDbUser(),
    config.getDbHost(),
    config.getDbPass()
  )

when not defined(iHaveMyOwnStuffThanks):
  echo "Adding fake users"
  for user in getFakeUsers():
    db.addUser(user)

  echo "Adding fake posts"
  for post in getFakePosts():
    db.addPost(post)
    db.addBulkReactions(post.id, getFakeReactions())
    db.addBulkBoosts(post.id, getFakeBoosts())
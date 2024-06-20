discard """
  action: "run"
  batchable: true
  joinable: true
  
  #valgrind: false   # Can use Valgrind to check for memory leaks, or not (Linux 64Bit only).
  
  # Targets to run the test into (c, cpp, objc, js). Defaults to c.
  targets: "cpp"
  
  # flags with which to run the test, delimited by `;`
  matrix: "-d:release ; -d:phPrivate -d:release ; -d:debug ; -d:debug -d:phPrivate"

"""

import potholepkg/[database, conf, post], debug


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
  db = setup(config)

when not defined(iHaveMyOwnStuffThanks):
  echo "Adding fake users"
  for user in getFakeUsers():
    discard db.addUser(user)

  echo "Adding fake posts"
  for post in getFakePosts():
    discard db.addPost(post)
    db.addBulkReactions(post.id, getFakeReactions())
    db.addBulkBoosts(post.id, getFakeBoosts())
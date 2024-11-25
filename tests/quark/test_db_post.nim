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

import quark/[user, post], debug
import pothole/[conf, database]
import std/strutils

const
  dbName{.strdefine.} = "pothole"
  dbUser{.strdefine.} = "pothole"
  dbHost{.strdefine.} = "127.0.0.1:5432"
  dbPass{.strdefine.} = "SOMETHING_SECRET"

# A basic config so that we don't error out.
var exampleConfig = ""

exampleConfig.add """
[db]
host="$#"
name="$#"
user="$#"
password="$#"
""" % [dbHost, dbName, dbUser, dbPass]

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
# Now let's get started!

## getTotalPosts
echo  "Testing getTotalPosts() "
assert db.getTotalPosts() == len(fakeStatuses), "Fail! (result: " & $db.getTotalPosts() & " len: " & $len(fakeStatuses) & ")"

# For these next few tests, it helps to have a post we control every aspect of.
let content = "@scout @soldier @pyro @demoman @heavy @engineer @medic @sniper @spy Wow! You will never be able to read what I said previously because something has mysteriously changed my post!"
var custompost = newPost(
  sender = "johnadminson",
  content = content,
  recipients = @["scout","soldier","pyro","demoman","heavy","engineer","medic","sniper","spy"],
  local = true
)

# We need to quickly test for if johnadminson exists.
if not db.userIdExists("johnadminson"):
  var user = newUser(
    "johnadminson",
    true,
    "123"
  )
  user.id = "johnadminson"
  user.admin = true
  user.salt = ""
  user.password = ""
  db.addUser(user)

db.addPost(custompost)

## postIdExists
echo "Testing postIdExists() "
assert db.postIdExists(custompost.id) == true, "Fail!"

## updatePost
echo "Testing updatePost() "
db.updatePost(custompost.id,"content",content)
assert db.getPost(custompost.id).content == content, "Fail! (result: " & db.getPost(custompost.id).content & ")"
custompost.content = content # We update this now so that the rest of the test code doesn't break

## Ok so the database code throws out the nanoseconds, which is reasonable
## since who the hell needs that much precision in a microblogging server.
## So we have to manually clear the nanoseconds.
## But also we can't just re-assign the nanoseconds so we have to convert it to
## the actual database format. Blame std/times for not exposing the actual object fields.
custompost.written = toDateFromDb(toDbString(custompost.written))

## getPost
echo "Testing getPost() "
assert db.getPost(custompost.id) == custompost, "Fail!"

## getPostsByUserHandle()
echo "Testing getPostsByUserHandle() "
assert db.getPostsByUserHandle("johnadminson",1).len() > 0, "Fail!\n\nresult: " & $(db.getPostsByUserHandle("johnadminson",1)) & "\n\n post: " & $(custompost)
 
## getPostsByUserId()
echo "Testing getPostsByUserId() "
assert db.getPostsByUserId("johnadminson",1).len() > 0, "Fail! (result: " & $(db.getPostsByUserId("johnadminson",1)) & " post: " & $(custompost) & ")"
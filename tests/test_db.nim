echo "Test 01 - Database Operations"
import std/tables
import debug

echo("Version reported: ", version)
const dbEngine*{.strdefine.} = "sqlite"
echo("Database engine: ", dbEngine)

echo "Initializing database"

when dbEngine == "sqlite":
  var
    config = {"db:filename": "main.db"}.toTable()
    db = init(config)

when not defined(iHaveMyOwnStuffThanks):
  echo "Adding fake users"
  for user in getFakeUsers():
    discard db.addUser(user.escape())

  echo "Adding fake posts"
  for post in getFakePosts():
    discard db.addPost(post.escape())

## getTotalPosts
stdout.write "\nTesting getTotalPosts() "
try:
  assert db.getTotalPosts() == len(fakeStatuses)
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  stdout.write "result: " & $db.getTotalPosts() & "\n"
  stdout.write "len: " & $len(fakeStatuses) & "\n"

# Uncomment this if you want, I guess?
## getLocalPosts
echo "Displaying local Posts"
for x in db.getLocalPosts(0):
  stdout.write("\n---\n")
  echo "From: @", x.sender
  if isEmptyOrWhitespace(x.replyto):
    echo "To: Public"
  else:
    var printOut: string = ""
    for user in x.recipients:
      printOut.add("@" & user)
    echo "To: ", printOut
  echo "\n" & x.content
  stdout.write("\n")
#]#


## getAdmins
stdout.write "Testing getAdmins() "
# Create a new admin user
var adminuser = newUser("johnadminson","John Adminson","123",true)
adminuser.admin = true
adminuser.bio = "I am John Adminson! The son of the previous admin, George Admin"
adminuser.email = "johnadminson@adminson.family.testinternal" # inb4 Google creates a testinternal TLD
discard db.addUser(escape(adminuser))

var adminFlag = false # This flag will get flipped when it sees the name "johnadminson" in the list of names that getAdmins() provides. If this happens then the test passes!
for handle in db.getAdmins():
  if handle == adminuser.handle:
    adminFlag = true
    break

try:
  assert adminFlag == true
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  stdout.write "getAdmins: " & $db.getAdmins() & "\n"

## getTotalLocalUsers
stdout.write "Testing getTotalLocalUsers() "
# By this point we have added the fakeUsers + our fake admin user above.
# So let's just test for this:
try:
  assert db.getTotalLocalUsers() > len(fakeHandles)
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  stdout.write "result: " & $db.getTotalLocalUsers() & "\n"
  stdout.write "len: " & $len(fakeHandles) & "\n"

## userIdExists
stdout.write "Testing userIdExists() "
# We already have a user whose ID we know.
# We can check for its ID easily.
try:
  assert db.userIdExists(adminuser.id) == true
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  stdout.write "result: " & $db.userIdExists(adminuser.id) & "\n"
  stdout.write "id: " & adminuser.id & "\n"

## userHandleExists
stdout.write "Testing userHandleExists() "
# Same exact thing but with the handle this time.
try:
  assert db.userHandleExists(adminuser.handle) == true
  stdout.write("Pass!\n")
except:
  stdout.write "Fail!\n"
  stdout.write "result: " & $db.userHandleExists(adminuser.handle) & "\n"
  stdout.write "handle: " & adminuser.handle & "\n"

## getUserById
stdout.write "Testing getUserById() "
try:
  assert db.getUserById(adminuser.id) == adminuser
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  stdout.write "result: " & $db.getUserById(adminuser.id) & "\n"
  stdout.write "adminuser: " & $adminuser & "\n"

## getUserByHandle
stdout.write "Testing getUserByHandle() "
try:
  assert db.getUserByHandle(adminuser.handle) == adminuser
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  stdout.write "result: " & $db.getUserByHandle(adminuser.handle) & "\n"
  stdout.write "adminuser: " & $adminuser & "\n"

## getIdFromHandle
stdout.write "Testing getIdFromHandle() "
try:
  assert db.getIdFromHandle(adminuser.handle) == adminuser.id
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  stdout.write "result: " & db.getIdFromHandle(adminuser.handle) & "\n"
  stdout.write "handle: " & adminuser.handle & "\n"
  stdout.write "id: " & adminuser.id & "\n"

## getHandleFromId
stdout.write "Testing getHandleFromId() "
try:
  assert db.getHandleFromId(adminuser.id) == adminuser.handle
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  stdout.write "result: " & db.getHandleFromId(adminuser.handle) & "\n"
  stdout.write "id: " & adminuser.id & "\n"
  stdout.write "handle: " & adminuser.handle & "\n"

## updateUserByHandle
# Make the johnadminson user no longer admin(son)
stdout.write "Testing updateUserByHandle() "
try:
  discard db.updateUserByHandle(adminuser.handle,"admin","false")
  assert db.getUserByHandle(adminuser.handle).admin == false
  stdout.write("Pass!\n")
except:
  stdout.write("Fail!\n")

## updateUserById
# Make the johnadminson user admin(son)
stdout.write "Testing updateUserById() "
try:
  discard db.updateUserById(adminuser.id,"admin","true")
  assert db.getUserById(adminuser.id).admin == true
  stdout.write("Pass!\n")
except:
  stdout.write("Fail!\n")

# For these next few tests, it helps to have a post we control every aspect of.
var custompost = newPost("johnadminson","","@scout @soldier @pyro @demoman @heavy @engineer @medic @sniper @spy Debate: is it pronounced Gif or Jif?",@["scout","soldier","pyro","demoman","heavy","engineer","medic","sniper","spy"],true)

discard db.addPost(custompost)

## postIdExists
stdout.write "Testing postIdExists() "
try:
  assert db.postIdExists(custompost.id) == true
  stdout.write("Pass!\n")
except:
  stdout.write("Fail!\n")

## updatePost
stdout.write "Testing updatePost() "
try:
  discard db.updatePost(custompost.id,"content","\"@scout @soldier @pyro @demoman @heavy @engineer @medic @sniper @spy Wow! You will never be able to read what I said previously because something has mysteriously changed my post!\"")
  assert db.getPost(custompost.id).content == "@scout @soldier @pyro @demoman @heavy @engineer @medic @sniper @spy Wow! You will never be able to read what I said previously because something has mysteriously changed my post!"
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  stdout.write "result: " & db.getPost(custompost.id).content & "\n"

## Ok so the database code throws out the nanoseconds, which is reasonable
## since who the hell needs that much precision in a microblogging server.
## So we have to manually clear the nanoseconds.
## But also we can't just re-assign the nanoseconds so we have to convert it to
## the actual database format. Blame std/times for not exposing the actual fields.
custompost.written = toDate(toString(custompost.written))
custompost.updated = toDate(toString(custompost.updated))

## getPost
stdout.write "Testing getPost() "
try:
  # We changed customPost because of the previous test, remember?
  custompost.content = "@scout @soldier @pyro @demoman @heavy @engineer @medic @sniper @spy Wow! You will never be able to read what I said previously because something has mysteriously changed my post!"
  assert db.getPost(custompost.id) == custompost
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  let result = db.getPost(custompost.id)
  for key, val in result.fieldPairs:
    if val != custompost.get(key):
      echo key, " does not match!"
      echo "---"
      echo "result: ", $val
      echo "custompost: ", $(custompost.get(key))
      echo "---\n\n"
  if result.revisions != custompost.revisions:
    echo result.revisions[0]
    echo len(result.revisions)

## getPostsByUserHandle()
stdout.write "Testing getPostsByUserHandle() "
try:
  assert db.getPostsByUserHandle("johnadminson",1)[0].id == custompost.id
  stdout.write("Pass!\n")
except:
  stdout.write("Fail!\n")
  stdout.write "result: " & $(db.getPostsByUserHandle("johnadminson",1)) & "\n"
  stdout.write "post: " & $(custompost) & "\n\n"

## getPostsByUserId()
stdout.write "Testing getPostsByUserId() "
try:
  assert db.getPostsByUserId(adminuser.id,1)[0].id == custompost.id
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"
  stdout.write "result: " & $(db.getPostsByUserId("johnadminson",1)) & "\n"
  stdout.write "post: " & $(custompost) & "\n\n"
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

## getTotalPosts
stdout.write "\nTesting getTotalPosts() "
try:
  assert getTotalPosts() == len(fakeStatuses)
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"

#[ Uncomment this if you want, I guess?
## getLocalPosts
echo "Displaying local Posts"
  for x in getLocalPosts(0):
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
]#


## getAdmins
stdout.write "Testing getAdmins() "
# Create a new admin user
var adminuser = newUser("johnadminson","John Adminson","123",true,true)
adminuser.bio = "I am John Adminson! The son of the previous admin, George Admin"
adminuser.email = "johnadminson@adminson.family.testinternal" # inb4 Google creates a testinternal TLD
discard db.addUser(escape(adminuser))

var adminFlag = false # This flag will get flipped when it sees the name "johnadminson" in the list of names that getAdmins() provides. If this happens then the test passes!
for handle in getAdmins():
  if handle == adminuser.handle:
    adminFlag = true
    break

try:
  assert adminFlag == true
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"

## getTotalLocalUsers
stdout.write "Testing getTotalLocalUsers() "
# By this point we have added the fakeUsers + our fake admin user above.
# So let's just test for this:
try:
  assert getTotalLocalUsers() > len(fakeHandles)
  stdout.write "Pass!\n"
except:
  stdout.write "Fail!\n"

## userIdExists
stdout.write "Testing userIdExists() "
# We already have a user whose ID we know.
# We can check for its ID easily.
try:
  assert userIdExists(adminuser.id) == true
  stdout.write("Pass!\n")
except:
  stdout.write "Fail!\n"

## userHandleExists
stdout.write "Testing userHandleExists() "
# Same exact thing but with the handle this time.
try:
  assert userHandleExists(adminuser.handle) == true
  stdout.write("Pass!\n")
except:
  stdout.write "Fail!\n"

## getUserById
stdout.write "Testing getUserById() "
try:
  assert getUserById(adminuser.id) == adminuser
  stdout.write("Pass!\n")
except:
  stdout.write("Fail!\n")

## getUserByHandle
stdout.write "Testing getUserByHandle() "
try:
  assert getUserByHandle(adminuser.handle) == adminuser
  stdout.write("Pass!\n")
except:
  stdout.write("Fail!\n")

## getIdFromHandle
stdout.write "Testing getIdFromHandle() "
try:
  assert getIdFromHandle(adminuser.handle) == adminuser.id
  stdout.write("Pass!\n")
except:
  stdout.write("Fail!\n")

## getHandleFromId
stdout.write "Testing getHandleFromId() "
try:
  assert getHandleFromId(adminuser.id) == adminuser.handle
  stdout.write("Pass!\n")
except:
  stdout.write("Fail!\n")

## updateUserByHandle
# Make the johnadminson user no longer admin(son)
stdout.write "Testing updateUserByHandle() "
try:
  discard updateUserByHandle(adminuser.handle,"admin","false")
  assert getUserByHandle(adminuser.handle).admin == false
  stdout.write("Pass!\n")
except:
  stdout.write("Fail!\n")

## updateUserById
# Make the johnadminson user admin(son)
stdout.write "Testing updateUserById() "
try:
  discard updateUserById(adminuser.id,"admin","true")
  assert getUserById(adminuser.id).admin == true
  stdout.write("Pass!\n")
except:
  stdout.write("Fail!\n")
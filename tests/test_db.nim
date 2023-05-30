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

stdout.write "\nTesting getTotalPosts() "
assert getTotalPosts() == len(fakeStatuses)
stdout.write "Pass! \n"

#[ Uncomment this if you want, I guess?
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

assert adminFlag == true
stdout.write "Pass!\n"

stdout.write "Testing getTotalLocalUsers() "
# By this point we have added the fakeUsers + our fake admin user above.
# So let's just test for this:
assert getTotalLocalUsers() > len(fakeHandles)
stdout.write "Pass!\n"
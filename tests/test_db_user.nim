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

import potholepkg/[database, conf, user, lib], debug


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
  db = init(config)

# Now let's get started!

## getAdmins
echo "Testing getAdmins() "
# Create a new admin user
var adminuser = newUser("johnadminson",true,"123")
adminuser.admin = true
adminuser.id = "johnadminson"
adminuser.password = ""
adminuser.salt = ""
if not db.userIdExists("johnadminson"):
  echo "Adding admin user"
  discard db.addUser(adminuser)

var adminFlag = false # This flag will get flipped when it sees the name "johnadminson" in the list of names that getAdmins() provides. If this happens then the test passes!
for handle in db.getAdmins():
  if handle == adminuser.handle:
    adminFlag = true
    break

assert adminFlag == true, "Fail!\ngetAdmins: " & $db.getAdmins()

## getTotalLocalUsers
echo "Testing getTotalLocalUsers() "
# By this point we have added the fakeUsers + our fake admin user above.
# So let's just test for if the value returned by getTotalLocalUsers is the same as our fake users + 1
assert db.getTotalLocalUsers() == len(fakeHandles) + 2, "Fail! (result: " & $db.getTotalLocalUsers() & " len: " & $len(fakeHandles) & ")"

## userIdExists
echo "Testing userIdExists() "
# We already have a user whose ID we know.
# We can check for its ID easily.
assert db.userIdExists(adminuser.id) == true, "Fail! (result: " & $db.userIdExists(adminuser.id) & "id: " & adminuser.id & ")"

## userHandleExists
echo "Testing userHandleExists() "
# Same exact thing but with the handle this time.
assert db.userHandleExists(adminuser.handle) == true, "Fail! (result: " & $db.userHandleExists(adminuser.handle) & "handle: " & adminuser.handle & ")"

proc findMismatch(u, u2: User) = 
  for fld, val in u.fieldPairs:
    if u.get(fld) != u2.get(fld):
      echo fld, ": ", u.get(fld), " != ", u2.get(fld)


## getUserById
echo "Testing getUserById() "
if db.getUserById(adminuser.id) != adminuser:
  findMismatch(db.getUserById(adminuser.id), adminuser)
assert db.getUserById(adminuser.id) == adminuser

## getUserByHandle
echo "Testing getUserByHandle() "
if db.getUserByHandle(adminuser.handle) != adminuser:
  findMismatch(db.getUserByHandle(adminuser.handle), adminuser)
assert db.getUserByHandle(adminuser.handle) == adminuser, "Fail!"

## getIdFromHandle
echo "Testing getIdFromHandle() "
assert db.getIdFromHandle(adminuser.handle) == adminuser.id, "Fail! (result: " & db.getIdFromHandle(adminuser.handle) & "handle: " & adminuser.handle & "id: " & adminuser.id & ")"

## getHandleFromId
echo "Testing getHandleFromId() "
assert db.getHandleFromId(adminuser.id) == adminuser.handle, "Fail! (result: " & db.getHandleFromId(adminuser.handle) & "id: " & adminuser.id & "handle: " & adminuser.handle & ")"

## updateUserByHandle
# Make the johnadminson user no longer admin(son)
echo "Testing updateUserByHandle() "
discard db.updateUserByHandle(adminuser.handle,"admin","false")
adminuser.admin = false
if db.getUserByHandle(adminuser.handle) != adminuser:
  findMismatch(db.getUserByHandle(adminuser.handle), adminuser)
assert db.getUserByHandle(adminuser.handle).admin == false, "Fail!"

## updateUserById
# Make the johnadminson user admin(son)
echo "Testing updateUserById() "
discard db.updateUserById(adminuser.id,"admin","true")
adminuser.admin = true
if db.getUserById(adminuser.id) != adminuser:
  findMismatch(db.getUserById(adminuser.id), adminuser)
assert db.getUserById(adminuser.id).admin == true, "Fail (result: " & $db.getUserById(adminuser.id) & ")"
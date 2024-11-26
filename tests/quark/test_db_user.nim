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

import quark/[users, debug, db], quark/private/macros
import pothole/[database, conf]
import std/[strutils, unittest]

# Let's get started!
var dbcon = connectToDb()

proc findMismatch(u, u2: User) = 
  for fld, val in u.fieldPairs:
    if u.get(fld) != u2.get(fld):
      echo fld, ": ", u.get(fld), " != ", u2.get(fld)

echo "Creating admin user, as a test but also for future tests"
var adminuser = newUser("johnadminson",true,"")
adminuser.admin = true # Set admin privileges
adminuser.moderator = true # Set mod privileges
adminuser.id = "johnadminson" # Set id to something easy to remember
dbcon.addUser(adminuser)

suite "User-related tests":
  test "getAdmins":
    # This boolean will get flipped it sees our handmade admin user.
    var adminFlag = false
    for handle in dbcon.getAdmins():
      if handle == adminuser.handle:
        adminFlag = true
        break
    assert adminFlag == true, "Fail! getAdmins: " & $(dbcon.getAdmins())
  
  test "getTotalLocalUsers":
    assert dbcon.getTotalLocalUsers() > 0, "result: " & $(dbcon.getTotalLocalUsers())
  
  test "userIdExists":
    assert dbcon.userIdExists("johnadminson"), "Fail!"
  
  test "userHandleExists":
    assert dbcon.userHandleExists("johnadminson"), "Fail!"
  
  test "getUserById":
    if dbcon.getUserById("johnadminson") != adminuser:
      findMismatch(dbcon.getUserById("johnadminson"), adminuser)
    assert dbcon.getUserById("johnadminson") == adminuser
  
  test "getUserByHandle":
    if dbcon.getUserByHandle("johnadminson") != adminuser:
      findMismatch(dbcon.getUserByHandle("johnadminson"), adminuser)
    assert dbcon.getUserByHandle("johnadminson") == adminuser, "Fail!"
  
  test "getIdFromHandle":
    assert dbcon.getIdFromHandle("johnadminson") == "johnadminson", "Fail! result: " & dbcon.getIdFromHandle(adminuser.handle)
  
  test "getHandleFromId":
    assert dbcon.getHandleFromId("johnadminson") == "johnadminson", "Fail! result: " & dbcon.getHandleFromId(adminuser.handle)
  
  test "updateUserByHandle":
    # Make the admin user no longer an admin.
    dbcon.updateUserByHandle("johnadminson", "admin", "false")
    var adminFlag = true
    for admin in dbcon.getAdmins():
      if admin == "johnadminson":
        adminFlag = false
        break
    assert adminFlag == true
  
  test "updateUserById":
    dbcon.updateUserById("johnadminson", "admin", "true")
    var adminFlag = false
    for admin in dbcon.getAdmins():
      if admin == "johnadminson":
        adminFlag = true
        break
    assert adminFlag == true
  




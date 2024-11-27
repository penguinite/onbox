import quark/[users, debug, crypto], quark/private/macros
import pothole/[database, conf]
import std/[unittest]

#testGuard("quark", "users")

# Let's get started!
var dbcon = connectToDb()

proc findMismatch(u, u2: User) = 
  for fld, val in u.fieldPairs:
    if u.get(fld) != u2.get(fld):
      echo "[MISMATCH] ", fld, ": ", u.get(fld), " != ", u2.get(fld)

echo "Creating admin user, as a test but also for future tests"
var adminuser = newUser("johnadminson",true,"")
adminuser.admin = true # Set admin privileges
adminuser.moderator = true # Set mod privileges
adminuser.id = "johnadminson" # Set id to something easy to remember
dbcon.addUser(adminuser)

echo "Creating a simple user who is used for email-related tests"
# Make another user whose email we have
var u1 = newUser("administrator", true)
u1.email = "administrator@tf-industries.int"
u1.id = "administrator"
dbcon.addUser(u1)

echo "Creating a frozen user"
var u2 = newUser("badman", true)
u2.is_frozen = true
dbcon.addUser(u2)

echo "Creating an unapproved user"
u2 = newUser("unapprovedman", true)
u2.is_approved = false
dbcon.addUser(u2)

echo "Creating an approved user"
u2 = newUser("approvedman", true)
u2.is_approved = true
dbcon.addUser(u2)

echo "Creating an unverified user"
u2 = newUser("unverifiedman")
u2.is_verified = false
dbcon.addUser(u2)

echo "Creating an verified user"
u2 = newUser("verifiedman")
u2.is_verified = true
dbcon.addUser(u2)

suite "User-related tests":
  test "getAdmins":
    # This boolean will get flipped it sees our handmade admin user.
    var adminFlag = false
    for handle in dbcon.getAdmins():
      if handle == adminuser.handle:
        adminFlag = true
        break
    assert adminFlag == true
  
  test "getTotalLocalUsers":
    assert dbcon.getTotalLocalUsers() > 0
  
  test "userIdExists":
    assert dbcon.userIdExists("johnadminson")
  
  test "userHandleExists":
    assert dbcon.userHandleExists("johnadminson")
  
  test "getUserById":
    if dbcon.getUserById("johnadminson") != adminuser:
      findMismatch(dbcon.getUserById("johnadminson"), adminuser)
    assert dbcon.getUserById("johnadminson") == adminuser
  
  test "getUserByHandle":
    if dbcon.getUserByHandle("johnadminson") != adminuser:
      findMismatch(dbcon.getUserByHandle("johnadminson"), adminuser)
    assert dbcon.getUserByHandle("johnadminson") == adminuser
  
  test "getIdFromHandle":
    assert dbcon.getIdFromHandle("johnadminson") == "johnadminson"
  
  test "getHandleFromId":
    assert dbcon.getHandleFromId("johnadminson") == "johnadminson"
  
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
  
  test "sanitizeHandle":
    for test in @[
      ("scout", "scout"),
      ("alex@wonderland.gov", "alex@wonderland.gov"),
      ("\"Please sanitize me", "pleasesanitizeme"),
      ("Vi maler byen rød og himmelen blå", "vimalerbyenrdoghimmelenbl"),
      ("Xi金平", "xi"),
      ("Mikuの消失","miku")
    ]:
      if sanitizeHandle(test[0]) != test[1]:
        echo "SANITIZEHANDLE TEST FAILED!"
        echo "Test input: ", test[0]
        echo "Expected output: ", test[1]
        echo "Returned output: ", sanitizeHandle(test[0])
        raise newException(AssertionDefect, "sanitizeHandle test failed.")
  
  test "newUser":
    # We make two users with the same data
    # And check them to see if they're the same.
    # They shouldn't be the same.
    var
      u1 = newUser("john",true)
      u2 = newUser("john",true)
    assert u1 != u2
  
  test "getDomains":
    # Let's make a couple of federated users.
    # 2 separate domains with 1 user each
    dbcon.addUser(newUser("alice@wonderland.local"))
    dbcon.addUser(newUser("bob@bobland.home"))

    # len(handleList) users on their own domain
    let handleList = @[
      "shoushitsu", "shuuen", "tanjo", "fukkatsu",
      "tomadoi", "bousou", "bunretsu-hakai", "gekishou",
      "asoubou", "sayonara", "choudou"
    ]
    for handle in handleList:
      dbcon.addUser(newUser(handle & "@infinitysongseries.cosmobsp"))
    
    let table = dbcon.getDomains()
    assert table.hasKey("bobland.home")
    assert table.hasKey("wonderland.local")
    assert table["infinitysongseries.cosmobsp"] == len(handleList)
  
  test "getTotalDomains":
    assert dbcon.getTotalDomains() == 3

  test "userEmailExists":
    assert dbcon.userEmailExists(u1.email)
  
  test "getUserIdByEmail":
    assert dbcon.getUserIdByEmail(u1.email) == "administrator"
  
  test "getUserSalt":
    assert dbcon.getUserSalt("administrator") == u1.salt
  
  test "getUserPass":
    assert dbcon.getUserPass("administrator") == u1.password
  
  test "isAdmin":
    assert dbcon.isAdmin("johnadminson") == true
    assert dbcon.isAdmin("administrator") == false

  test "isModerator":
    assert dbcon.isModerator("johnadminson") == true
    assert dbcon.isModerator("administrator") == false

  test "getUserKDF":
    assert dbcon.getUserKDF("administrator") == crypto.latestKdf
  
  test "userFrozen":
    assert dbcon.userFrozen("administrator") == false
    assert dbcon.userFrozen("badman") == true
  
  test "userVerified":
    assert dbcon.userVerified("verifiedman") == true
    assert dbcon.userVerified("unverifiedman") == false
  
  test "userApproved":
    assert dbcon.userApproved("approvedman") == true
    assert dbcon.userApproved("unapprovedman") == false
  
  test "getFirstAdmin":
    assert dbcon.getFirstAdmin() != ""
  
  test "adminAccountExists":
    assert dbcon.adminAccountExists() == true
  
  test "getUserBio":
    for data in userData:
      assert dbcon.getUserBio(data[0]) == data[2]

  test "deleteUser":
    var scout = newUser("scout", true)
    scout.name = "Jeremy"
    scout.bio = "All the ladies love me!"
    dbcon.deleteUser("scout")
    assert dbcon.userIdExists("scout") == false
    dbcon.addUser(scout)

  test "deleteUsers":
    for user in @[
      newUser("johnny",true),
      newUser("katie",true)
    ]:
      dbcon.addUser(user)
    assert dbcon.userIdExists("johnny") == true
    assert dbcon.userIdExists("katie") == true
    dbcon.deleteUsers("johnny", "katie")
    assert dbcon.userIdExists("johnny") == true
    assert dbcon.userIdExists("katie") == true
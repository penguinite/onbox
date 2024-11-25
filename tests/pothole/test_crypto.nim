echo "Test 03 - Password hashing & Cryptography"

import quark/crypto

# Testing hashing algos.
for item in @[
  (1, "cannabis abyss", "__eat_flaming_death", "MTYxMTQyMTUxMjAzNzA=MTY4MTUzMTczMTQ5MTIyMTY5Mzg=NDE=OTA=MjEyMTE1MjE4NQ==MTUyMw==MjAwMjQxOTM=MTY2MTU=MTk1MjA2MjU0MTk=MjEzMTE=MjE5")
]:
  echo "Testing algorithm #", item[0]
  assert hash(item[1], item[2], IntToKDF(item[0])) == item[3]
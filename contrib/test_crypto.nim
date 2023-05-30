echo "Test 01 - Cryptography"

import libpothole/crypto

echo "Testing random strings. Are all of these random?"
echo maxASCIILetters
for i in 0..1000:
  echo(randomString(24))
  
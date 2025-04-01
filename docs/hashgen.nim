import rng, std/strutils, std/base64, nimcrypto/pbkdf2, nimcrypto, std/os

proc hash*(password, salt:string, iter: int = 210000): string =
  ## We use PBKDF2-HMAC-SHA512 by default with 210000 iterations unless specified.
  ## This procedure is a wrapper over nimcrypto's PBKDF2 implementation
  ## This procedure returns a base64-encoded string.
  ## kdf ID: 1
  for x in pbkdf2(
      sha512,
      toOpenArray(password,0,len(password) - 1),
      toOpenArray(salt,0,len(salt) - 1),
      iter,
      32):
    result.add(encode($x, safe = true))
  return result

var output = ""
for i in 0..parseInt(paramStr(1)):
  let
    pass = rng.randstr(32)
    salt = rng.randstr()
    hash = hash(pass, salt)
  output.add "\n  (\"$1\", \"$2\", PBKDF_HMAC_SHA512, \"$3\")" % [
    pass, salt, hash
  ]
  
writeFile("test", output)
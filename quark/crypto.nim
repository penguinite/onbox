# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This file is part of Pothole.
# 
# Pothole is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Pothole is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Pothole. If not, see <https://www.gnu.org/licenses/>. 
#
# crypto.nim: 
## This module provides password hashing functions, and most importantly, the `KDF` object that is used when processing passwords for users.
## 
## This module also previously provided functions for fetching cryptographically-secure random data such as string, chars and ints but that job has been offloaded to [rng](https://github.com/penguinite/rng.git) in the main Pothole codebase.
## 
## To use KDF and the password hashing functions, you simply use the `hash()` function.
## If a user requires a specific algorithm then you can provide it in the `algo` parameter
runnableExamples:
  var
    password = "Hello World!"
    salt = "SomeRandomSalt"
  
  # Hashing with PBKDF-HMAC-SHA512, 210000 iterations.
  # This is the default algorithm since May 22 2024.
  let hash1 =  hash(password, salt, PBKDF_HMAC_SHA512)

  # You can also use IntToKDF if the algorithm is too hard to remember.
  let hash2 = hash(password, salt, IntToKDF(1))


# TODO: Remove this when all references to the deprecated functions are removed in the main Pothole codebase.
import rng
export rng

# For password hashing
import nimcrypto
import nimcrypto/pbkdf2
from std/base64 import encode

# Deprecated API:
proc randomInt*(limit: int = 18): int
  {.deprecated: "Use rng.randint() directly or a different random number generator".} =
  return rng.randint(limit)

proc rand*(dig: int = 5): int
  {.deprecated: "Use rng.rand() directly or a different random number generator".} =
  return rng.rand(dig)

proc randchar*(): char
  {.deprecated: "Use rng.randch() directly or a different random number generator".} =
  return rng.randch()

proc randomString*(limit: int = 16): string 
  {.deprecated: "Use rng.randstr() directly or a different random number generator".} =
  return rng.randstr(limit)


type
  KDF* = enum
    PBKDF_HMAC_SHA512

const kdf* = PBKDF_HMAC_SHA512 ## The latest Key Derivation Function supported by this build of pothole, check out the KDF section in the DESIGN.md document for more information.

proc KDFToInt*(algo: KDF): int =
  ## Converts a KDF object into a number
  ## TODO: Maybe merge this with the user.kdf field in the user.nim module???
  ## It doesn't make sense to keep this here, except to maybe avoid a circular dependency.
  case algo:
  of PBKDF_HMAC_SHA512: return 1

proc IntToKDF*(num: int): KDF =
  case num:
  of 1: return PBKDF_HMAC_SHA512
  else: return kdf

proc StringToKDF*(num: string): KDF =
  ## Converts a string to a KDF object.
  ## You can use this instead of IntToKDF for when you are dealing with database rows.
  ## (Which, in db_postgres, consist of seq[string])
  case num:
  of "1": return PBKDF_HMAC_SHA512
  else: return kdf


proc KDFToString*(kdf: KDF): string = 
  ## Converts a KDF object into a string.
  ## You could use to save nanoseconds when dealing with database logic.
  ## Honestly though, it might be too much. Even for me.
  case kdf:
  of PBKDF_HMAC_SHA512: return "1"

proc `$`*(k: KDF): string = 
  return KDFToString(k)

proc pbkdf2_hmac_sha512_hash(password, salt:string, iter: int = 210000): string =
  ## We use PBKDF2-HMAC-SHA512 by default with 210000 iterations unless specified.
  ## This procedure is a wrapper over nimcrypto's PBKDF2 implementation
  ## This procedure returns a base64-encoded string. You can specify the safe parameter of 
  ## encode() with the genSafe parameter
  ## kdf ID: 1
  runnableExamples:
    var password = "cannabis abyss"
    var salt = "__eat_flaming_death"
    # Hash the user's password
    var hashed_password = pbkdf2_hmac_sha512_hash(password, salt)
  for x in pbkdf2(
      sha512,
      toOpenArray(password,0,len(password) - 1),
      toOpenArray(salt,0,len(salt) - 1),
      iter,
      32):
    result.add(encode($x, safe = true))
  return result

proc hash*(password, salt: string, algo: KDF = kdf): string =
  ## Hashes a string with a salt with a specific algorithm or the default one.
  runnableExamples:
    var password = "cannabis abyss"
    var salt = "__eat_flaming_death"
    # Hash the user's password
    var hashed_password = hash(password, salt, PBKDF_HMAC_SHA512)
    echo "Magicum"
    echo hash(password, salt, PBKDF_HMAC_SHA512)
  case algo:
  of PBKDF_HMAC_SHA512: return pbkdf2_hmac_sha512_hash(password, salt, 210000)
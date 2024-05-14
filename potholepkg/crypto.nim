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
## This file provides functions related to cryptography.
## It provides wrapper functions for hashing, and it also provides several procedures to generate random numbers and strings.
## It would be nice if this was included in the standard library but we unfortunately have to rely on a third-party library and an experimental unauditted standard library (std/sysrand)
## 
## I am certain that this module is cryptographically secure
## but of course, feel free to audit it yourself.

import nimcrypto
import nimcrypto/pbkdf2

from std/base64 import encode
from std/sysrand import urandom
from std/strutils import parseInt

const asciiLetters: seq[char] = @[
  '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z' 
] # This is basically Base62

let maxASCIILetters* = len(asciiLetters) - 1 ## The length of asciiLetters minus one.

proc randomInt*(limit: int = 18): int =
  ## A function that generates an integer, limit is how many digits should be
  ## in the final string. ie. 10 generates a string that is 10 digits long.
  var tmp: string; # This string stores the int so that we get literal digits.
  for bit in urandom(limit):
    tmp.add($int(bit))
      
  return parseInt(tmp[0..limit - 1])

proc rand*(dig: int = 5): int =
  ## A replacement function for rand() that is actually cryptographically secure.
  ## The final integer will always be between 1 to X (where X is the argument to the number)
  runnableExamples:
    assert rand(5) < 6; # This is true since rand(5) returns a number between 1 and 5.
  var num = randomInt(len($dig))
  if num > dig:
    num = dig
  if num < 0:
    num = 0
  return num

proc randchar*(): char =
  ## Generates a random character.
  ## This should be unpredictable, it does not use std/random's rand()
  ## But it uses our replacement rand() function that is also secure.
  runnableExamples:
    echo("Your magic character is ", randchar())
  var bit = int(urandom(1)[0])
  if bit > maxASCIILetters or bit < 0:
    bit = rand(maxASCIILetters)
  return asciiLetters[bit]

proc randomString*(limit: int = 16): string = 
  ## A function to generate a safe random string.
  ## Used for salt & id generation and debugging (creating fake passwords)
  runnableExamples:
    echo("Here's a bunch of random and hopefully safe garbage: ", randomString())
  for i in 1..limit:
    result.add(randchar())
  return result

proc pbkdf2_hmac_sha512_hash(password, salt:string): string =
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
      210000,
      32):
    result.add(encode($x, safe = true))
  return result

type
  KDF* = enum
    PBKDF_HMAC_SHA512

const kdf* = PBKDF_HMAC_SHA512 ## The latest Key Derivation Function supported by this build of pothole, check out the KDF section in the DESIGN.md document for more information.

proc hash*(password, salt: string, algo: KDF = kdf): string =
  ## Hashes a string with a salt with the specific algorithm specified by Id
  runnableExamples:
    var password = "cannabis abyss"
    var salt = "__eat_flaming_death"
    # Hash the user's password
    var hashed_password = hash(password, salt, PBKDF_HMAC_SHA512)
  case algo:
  of PBKDF_HMAC_SHA512: return pbkdf2_hmac_sha512_hash(password, salt)

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
  case num:
  of "1": return PBKDF_HMAC_SHA512
  else: return kdf

  
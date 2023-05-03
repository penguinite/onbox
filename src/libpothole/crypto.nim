# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# crypto.nim: 
## This file provides functions related to randomness or hashing
## Most notably, it provides hash() which is used for lots of things
## And randomString() which is used for generating IDs and salts.
## I am certain that it is cryptographically secure
## But of course, feel free to audit it yourself.

import nimcrypto
import nimcrypto/pbkdf2

from std/base64 import encode
from std/sysrand import urandom
from std/strutils import parseInt

#! std/sysrand has not been evaluated or auditted. But read the below notice before modifying.
#[
  Previously this file used std/random's rand() function to generate a number and then that would
  be fed to a char function to create a string. This function was used to create strings for
  Post ids, User ids and password salts. But the std/random RNG is not cryptographically
  secure, it is possible to get the same output by simply running the program again.

  I feel like I don't need to tell you why that's a bad thing, the whole point of the salt is that it is
  somewhat obscure, but with std/random it was possible to just predict what salt would be next.
  Our password hash function is somewhat secure and so it wouldn't be as big of a deal but I still didn't
  like the fact that I would always get the same result no matter what.

  The moral of the story is, while other languages have good cryptographic libraries, Nim has no sort of thing
  like that, but I am okay with these risks so I will continue using nimcrypto and std/sysrand
]#

const trulySafeLetters: seq[char] = @[
  '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','~','-','_','.',':',';','=','@'
]
let maxSafeLetters = len(trulySafeLetters) - 1

const asciiLetters: seq[char] = @[
  '%','&','(',')','*','+',',','-','.','/','0','1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[',']','^','_','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','{','|','}','~'
] # This sequence has 89 entries (-1 is 88)
let maxASCIILetters = len(asciiLetters) - 1

proc randomInt*(limit: int = 18): int =
  ## A function that generates an integer, limit is how many digits should be
  ## in the final string. ie. 10 generates a string that is 10 digits long.
  var tmp: string; # This string stores the int so that we get literal digits.
  for bit in urandom(limit):
    tmp.add($int(bit))
      
  return parseInt(tmp[0..limit - 1])

proc rand*(dig: int = 5): int =
  ## A replacement function for rand() that is actually cryptographically secure.
  ## The final integer will always be 0 to X (where X is the argument to the number)
  runnableExamples:
    assert rand(5) < 6; # This is true since rand(5) returns a number between 0 and 5.
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
  var bit = int(urandom(1)[0])
  if bit > maxASCIILetters or bit < 0:
    bit = rand(maxASCIILetters)
  return asciiLetters[bit]

proc randomString*(limit: int = 18): string =
  ## A function to generate a random character.
  for i in 1..limit:
    result.add(randchar())
  return result

proc randsafechar*(): char =
  ## Generates a random safe character
  ## This is unpredictable and now safer for use in IDs!
  var bit = int(urandom(1)[0])
  if bit > maxSafeLetters or bit < 0:
    bit = rand(maxSafeLetters)
  return trulySafeLetters[bit]

proc randomSafeString*(limit: int = 16): string = 
  ## A function to generate a safe random string.
  ## Used for salt & id generation and debugging (creating fake passwords)
  for i in 1..limit:
    result.add(randsafechar())
  return result

proc hash*(password: string, salt:string, iter: int = 160000,outlen: int = 32, genSafe: bool = true): string =
  ## We use PBKDF2-HMAC-SHA512 by default with 160000 iterations unless specified.
  ## This procedure is a wrapper for nimcrypto's PBKDF2 implementation
  ## This procedure returns a base64-encoded string. You can specify the safe parameter of 
  ## encode() with the genSafe parameter
  var newhash: string = "";
  for x in pbkdf2(sha512, toOpenArray(password,0,len(password) - 1), toOpenArray(salt,0,len(salt) - 1), iter, outlen):
    newhash.add(encode($x, safe = genSafe))
  return newhash
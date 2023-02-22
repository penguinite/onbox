# Copyright © Leo Gavilieau 2022-2023
# Licensed under the AGPL version 3 or later.
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
  Post ids, User ids and password salts. But the std/random number generator is not cryptographically
  secure, it is possible to get the same output by simply running the program again.

  I feel like I don't need to tell you why that's a bad thing, the whole point of the salt is that it is
  somewhat obscure, but with std/random it was possible to just predict what salt would be next.
  Our password hash function is somewhat secure and so it wouldn't be as big of a deal but I still didn't
  like the fact that I would always get the same result no matter what.

  The moral of the story is, while other languages have good cryptographic libraries, Nim has no sort of thing
  like that, but I am okay with these risks so I will continue using nimcrypto and std/sysrand
]#

# echo(int('A') .. int('z')) = 65 .. 122
# But 37 .. 126 is fine

const asciiLetters: seq[char] = @[
  '%','&','(',')','*','+',',','-','.','/','0','1','2','3','4','5','6','7','8','9',':',';','<','=','>','?','@','A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X','Y','Z','[',']','^','_','a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z','{','|','}','~'
] # This sequence has 89 entries (-1 is 88)
let maxLetters = len(asciiLetters) - 1

proc randomInt*(limit: int = 18): int =
  ## A function that generates an integer, limit is how many digits should be
  ## in the final string. ie. 10 generates a string that is 10 digits long.
  var tmp: string; # This string stores the int so that we get literal digits.
  for bit in urandom(limit):
    tmp.add($int(bit))
      
  return parseInt(tmp[0..limit - 1])

proc rand*(dig: int = 5): int =
  ## A replacement function for rand() that is actually cryptographically secure.
  ## The final integer will always be 0 to dig (soo a number in the range of 0
  ## and 5 if your dig is 5)
  var num = randomInt(len($dig))
  if num > dig:
    num = dig
  
  return num

proc randchar*(): char =
  ## Generates a random character.
  ## This should be unpredictable, it does not use std/random's rand()
  ## But it uses our replacement rand() function that is also secure.
  var bit = int(urandom(1)[0])
  if bit > maxLetters:
    bit = rand(maxLetters)
  if bit < 0:
    bit = rand(maxLetters)
  return asciiLetters[bit]

proc randomString*(limit: int = 18): string =
  ## A function to generate a random string.
  ## Used for salt & id generation and debugging (creating fake passwords)
  for i in 1..limit:
    result.add(randchar())
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
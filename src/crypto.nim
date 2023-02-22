# Copyright © Leo Gavilieau 2022-2023
## This module provides an easy-to-use wrapper for nimcrypto's PBKDF2-HMAC-SHA512 implementation
## By default we use 160,000 iterations with that key-derivation function, NIST recommends 120,000 so we 
## will go a little overboard.

import nimcrypto
import nimcrypto/pbkdf2
import std/[base64, sysrand, strutils]

#! std/sysrand has not been evaluated or auditted. But the previous std/random method does *not* produce 
#! unpredictable bytes. So this option is not bad compared to using std/random for ID generation and salt generation.

proc randomString*(limit: int = 18): string =
  ## A function to generate a random string.
  ## Used for salt & id generation and debugging (creating fake passwords)
  for bit in urandom(limit):
    result.add(char(bit))

  return result
    
proc randomInt*(limit: int = 18): int =
  var tmp: string; # This string stores the int so that we get literal digits.
  for bit in urandom(limit):
    tmp.add($int(bit))
      
  return parseInt(tmp[0..limit - 1])


proc rand*(dig: int = 5): int =
  var num = randomInt(len($dig))
  if num > dig:
    num = dig
  
  return num

proc hash*(password: string, salt:string, iter: int = 160000,outlen: int = 32): string =
  ## We use PBKDF2-HMAC-SHA512 by default
  ## This procedure is a wrapper for nimcrypto's PBKDF2 implementation
  var newhash: string = "";
  for x in pbkdf2(sha512, toOpenArray(password,0,len(password) - 1), toOpenArray(salt,0,len(salt) - 1), iter, outlen):
    newhash.add(encode($x, safe = true))
  return newhash
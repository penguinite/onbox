# Copyright © Louie Quartz 2022-2023
## This module provides an easy-to-use wrapper for nimcrypto's PBKDF2-HMAC-SHA512 implementation
## By default we use 160,000 iterations with that key-derivation function, NIST recommends 120,000 so we 
## will go a little overboard.

import nimcrypto
import nimcrypto/pbkdf2
import std/[base64, random]

proc randomString*(endlen: int = 18): string =
  for i in 0 .. endlen:
    if rand(5) == 1:
      add(result, $rand(10))
    else:
      add(result, char(rand(int('A') .. int('z'))))
      

# We use PBKDF2-HMAC-SHA512 by default
# This procedure is a wrapper for nimcrypto's PBKDF2 implementation
proc hash*(password: string, salt:string, iter: int = 160000,outlen: int = 32): string =
  var newhash: string = "";
  for x in pbkdf2(sha512, toOpenArray(password,0,len(password) - 1), toOpenArray(salt,0,len(salt) - 1), iter, outlen):
    newhash.add(encode($x, safe = true))
  return newhash
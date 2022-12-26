# A test program to demonstrate the crypto wrapper
# This program should be placed in src/ but we do not
# even use it.

import crypto

proc exit {.noconv.} =
  quit(0)

setControlCHook(exit)

# Demonstrating crypto
# This thing is slow but that's a good thing.
# We won't be authenticating sessions every five seconds.
for x in 0 .. 99:
  echo(hash("salt" & $x,$x & "password" & $x))
## This MRF policy rejects any user whose name or handle contains "alex"
{.push cdecl, dynlib, exportc.}

import pothole/mrf, std/strutils

#! Incoming data refers to data from the outside world sent to the instance.

proc filterIncomingUser*(user: User, config: ConfigTable): User  = 
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  if "alex" notin user.name.toLowerAscii() and "alex" notin user.handle.toLowerAscii():
    result = user
  return result
# Note: MRF Policies are considered to be under the AGPL since they do rely on pothole's source code.
# So make sure to release your MRF policies under the same license.


{.push cdecl, dynlib, exportc.}

import pothole/mrf 

#! Incoming data refers to data from the outside world sent to the instance.

proc filterIncomingPost*(post: Post, config: ConfigTable): Post =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return

proc filterIncomingUser*(user: User, config: ConfigTable): User  = 
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return

proc filterIncomingActivity*(activity: Activity, config:ConfigTable): Activity =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return

#! Outgoing data refers to data sent from inside the instance going to other instances.

proc filterOutgoingPost*(post: Post, config:ConfigTable): Post =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return

proc filterOutgoingUser*(user: User, config:ConfigTable): User =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return


proc filterOutgoingActivity*(activity: Activity, config:ConfigTable): Activity =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return

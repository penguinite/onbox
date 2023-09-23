

# Note: MRF Policies are considered to be under the AGPL since they do rely on libpothole.
# So make sure to release your code.

import std/tables


## Replace these with a single import to libpothole/mrf
## pothole isn't yet a hybrid package so this will have to wait.
type
  User* = object
  Post* = object
  Activity* = object

const
  ## These three are mostly used to provide some human-readable metadata.
  ## All of these are optional, although its useful to provide them.
  ## Otherwise you would see example_policy.so instead of "Example Policy"
  # MRF Policy name. 
  name* {.exportc.} = "Example Policy"
  # MRF Policy author
  author* {.exportc.} = "John Doe"
  # A quick description
  description* {.exportc.} = "An example MRF policy, it does nothing whatsoever... But it serves as a starting point for your policy."
  # A url to provide source code, documentation or more.
  url* {.exportc.} = "https://ph.example.com/mrf_policies/example/"

  # What follows is intended more for machine readability.

  # What version of Pothole this MRF policy was written for.
  compat* {.exportc.} = "0.0.2"
  # What is the "keyword" of the policy.
  # This is used when configuring the policy in the config file.
  keyword* {.exportc.} = "example"

#! Incoming data refers to data from the outside world sent to the instance.

proc filterIncomingPost*(post: Post, config: Table[string, string]): Post {.cdecl, exportc, dynlib.} =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return

proc filterIncomingUser*(user: User, config: Table[string, string]): User {.cdecl, exportc, dynlib.} = 
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return

proc filterIncomingActivity*(activity: Activity, config: Table[string, string]): Activity {.cdecl, exportc, dynlib.} =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return

#! Outgoing data refers to data sent from inside the instance going to other instances.

proc filterOutgoingPost*(post: Post, config:Table[string, string]): Post {.cdecl, exportc, dynlib.} =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return

proc filterOutgoingUser*(user: User, config:Table[string, string]): User {.cdecl, exportc, dynlib.} =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return


proc filterOutgoingActivity*(activity: Activity, config:Table[string, string]): Activity {.cdecl, exportc, dynlib.} =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  return

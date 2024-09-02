# Note: MRF Policies are considered to be under the AGPL since they do rely on pothole's source code.
# So make sure to release your MRF policies under the same license.

## TODO: This won't compile with the new Post object model
## It should be easy to fix though, I just have more important things to do.

{.push cdecl, dynlib, exportc.}

import pothole/mrf, std/strutils

#! Incoming data refers to data from the outside world sent to the instance.

proc filterIncomingPost*(post: Post, config: ConfigTable): Post =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  result = post
  result.content = ""
  var flag = false
  for i in post.content:
    if flag:
      result.content.add(i.toLowerAscii())
      flag = false
    else:
      result.content.add(i.toUpperAscii())
      flag = true
  return result
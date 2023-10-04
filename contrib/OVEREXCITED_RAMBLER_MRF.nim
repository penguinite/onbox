# This policy makes everyone sound like an overexcited rambler.
# Ie. "Hello everyone" turns into "HELLO EVERYONE!!! :D"

import potholepkg/mrf
import std/strutils

{.push dynlib exportc.}

proc filterIncomingPost*(post: Post, config: Table[string, string]): Post =
  # Do stuff here.
  # Additionally, you can return a completely empty object if
  # you wish the MRF facility to reject it.
  result = post
  result.content = toUpper(post.content)

  result.content.add("!!! :D")
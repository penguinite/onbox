# Benchmarking strutils isEmptyOrWhitespace
# versus my own implement of it

import ../src/lib
from strutils import isEmptyOrWhitespace

proc isEmpty(str: string): bool =
  for x in str:
    if x notin whitespace:
      return true
  return false

# Running each procedure a thousand times.
const teststring = "      fe"
for x in 0 .. 1000:
  discard isEmptyOrWhitespace(teststring)

echo(isEmptyOrWhitespace(teststring))
echo(isEmpty(teststring))

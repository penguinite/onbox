import ../src/crypto

# Catch Ctrl+C so we can exit without causing a stacktrace
proc exit() {.noconv.} =
  quit(0)

setControlCHook(exit)

while(true):
  echo(randomString(100))
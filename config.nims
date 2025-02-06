switch("path","./src")
switch("stackTrace","on") # For better debugging
switch("d", "useMalloc") # Required for fixing memory leak.
switch("mm", "orc") # Required by mummy
switch("threads","on") # Required by mummy

## Based on https://scripter.co/nim-deploying-static-binaries
## Thank you Kaushal
when defined(musl):
  {.warning: "Building with musl. Note: This is not an officially supported build method.".}
  {.warning: "In other words, expect more strange bugs than usual!".}
  const muslgcc = findExe("musl-gcc")
  #if fileExists("/usr/local/musl/musl-gcc"):
    #muslgcc = "/usr/local/musl/musl-gcc"
  {.warning: "musl-gcc: " & muslgcc.}
  when muslgcc == "":
    {.error: "'musl-gcc' binary was not found in PATH.".}
    exit(1)
  switch("gcc.exe", muslgcc)
  switch("gcc.linkerexe", muslgcc)
  
  # Pothole needs libpq
  switch("passC", "-L /usr/local/musl")
  switch("passL", "-lpq -lpgport -lpgcommon")
  #switch("passL", "-static")
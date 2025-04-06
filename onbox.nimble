# Package

version       = "0.0.2"
author        = "penguinite"
description   = "A MastoAPI backend server and a general-purpose social media/microblogging library"
license       = "AGPL-3.0-or-later"
srcDir        = "src"
binDir        = "build"
bin           = @["onbox","onboxctl"]
backend       = "cpp"

## The following options are required
switch("stackTrace","on") # For better debugging
switch("mm", "orc") # Required by mummy
switch("d", "useMalloc") # Required for fixing memory leak, git blame and see commit msg.
switch("threads","on") # Required by mummy

after clean:
  for dir in ["static/", "uploads/", binDir]:
    if dirExists(dir): rmDir(dir)

task all, "Builds everything with versioning embedded.":
  exec "nimble -d:version=\"" & version & " - " & gorgeEx("git rev-parse HEAD^")[0] & "\" -d:release build"

from std/os import commandLineParams
task ctl, "Shorthand for nimble run onboxctl":
  proc cleanArgs(): seq[string] =
    commandLineParams()[commandLineParams().find("ctl") + 1..^1]
  exec("nimble build onboxctl")
  exec(binDir & "/onboxctl " & cleanArgs().join(" "))

task dev, "For running the internal developer tool.":
  proc cleanArgs(): seq[string] =
    commandLineParams()[commandLineParams().find("dev") + 1..^1]
  exec("nim c -o:$1/onboxdev $2/onboxdev" % [binDir, srcDir])
  if not dirExists(binDir):
    mkDir(binDir)
  if fileExists(srcDir & "/onboxdev"):
    mvFile(srcDir & "/onboxdev", binDir & "/onboxdev")
  exec(binDir & "/onboxdev " & cleanArgs().join(" "))

task musl, "A task to build a binary linked with musl rather than glibc":
  exec("nimble build -d:musl -d:release --opt:speed")

after build:
  cpFile("onbox.conf",binDir & "/onbox.conf")
  cpFile("LICENSE", binDir & "/LICENSE")

# Dependencies
requires "nim >= 2.0.0"
requires "nimcrypto >= 0.5.4"
requires "rng >= 0.2.0"
requires "iniplus#d9509566d442f597547f8c8aa9bd7599c71a93ff"
requires "temple >= 0.2.3"
requires "db_connector >= 0.1.0"
requires "mummy >= 0.4.2"
requires "waterpark >= 0.1.7"
requires "cligen >= 1.7.3"
requires "smtp"

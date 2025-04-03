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
  exec "nimble -d:oxVersion=\"" & version & " - " & gorgeEx("git rev-parse HEAD^")[0] & "\" -d:release build pothole"

from std/os import commandLineParams
task ctl, "Shorthand for nimble run onboxctl":
  proc cleanArgs(): seq[string] =
    ## commandLineParams() returns the command line params for the whole nimble commands.
    ## Which can fuck up the more advanced commands. (user new, post new and so on)
    ## So this command strips everything after the task name, which works well!
    return commandLineParams()[commandLineParams().find("ctl") + 1..^1]

  if dirExists(binDir) and fileExists(binDir & "/onboxctl"):
    exec binDir & "/onboxctl " & cleanArgs().join(" ")
    return
    
  if fileExists("onboxctl"):
    exec "./onboxctl " & cleanArgs().join(" ")
    return

  exec("nimble -d:release build onboxctl")
  exec(binDir & "/onboxctl " & cleanArgs().join(" "))

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

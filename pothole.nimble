# Package

version       = "0.0.2"
author        = "penguinite"
description   = "A lightweight and efficient microblogging server."
license       = "AGPL-3.0-or-later"
binDir        = "build"
bin           = @["pothole","potholectl"]
installDirs   = @["quark"]
backend       = "cpp"

## The following options are required
when not defined(phEmbedded):
  switch("stackTrace","on") # For better debugging
switch("mm", "orc") # Required by mummy
switch("d", "useMalloc") # Required for fixing memory leak, git blame and see commit msg.
switch("threads","on") # Required by mummy

task clean, "Removes build folders if it exists":
  if dirExists(binDir):
    rmdir(binDir)
  if dirExists("static/"):
    rmdir("static/")
  if dirExists("uploads/"):
    rmdir("uploads/")

from std/os import commandLineParams
task ctl, "Shorthand for nimble run potholectl":
  proc cleanArgs(): seq[string] =
    ## commandLineParams() returns the command line params for the whole nimble commands.
    ## Which can fuck up the more advanced commands. (user new, post new and so on)
    ## So this command strips everything after the task name, which works well!
    return commandLineParams()[commandLineParams().find("ctl") + 1..^1]

  if dirExists(binDir) and fileExists(binDir & "/potholectl"):
    exec binDir & "/potholectl " & cleanArgs().join(" ")
    return
    
  if fileExists("potholectl"):
    exec "./potholectl " & cleanArgs().join(" ")
    return

  exec("nimble -d:release build potholectl")
  exec(binDir & "/potholectl " & cleanArgs().join(" "))

after build:
  cpFile("pothole.conf",binDir & "/pothole.conf")
  cpFile("LICENSE", binDir & "/LICENSE")

# Dependencies
requires "nim >= 2.0.0"
requires "nimcrypto >= 0.5.4"
requires "rng >= 0.1.0"
requires "iniplus >= 0.2.2"
requires "https://github.com/penguinite/temple >= 0.2.2" # TODO: Add this as a nimble package
requires "db_connector >= 0.1.0"
requires "mummy >= 0.4.2"
requires "waterpark >= 0.1.7"

# Package

version       = "0.0.2"
author        = "penguinite"
description   = "A lightweight and efficient microblogging server."
license       = "AGPL-3.0-or-later"
binDir        = "build"
bin           = @["pothole","potholectl"]
installDirs    = @["potholepkg"]
backend       = "cpp"

## The following options are required
switch("stackTrace","on")
switch("mm", "orc")
switch("threads","on")

task clean, "Removes build folder if it exists":
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

  if fileExists("potholectl"):
    exec "./potholectl " & cleanArgs().join(" ")
    return

  if dirExists("build") and fileExists("build/potholectl"):
    exec "./build/potholectl " & cleanArgs().join(" ")
    return
  
  exec("nimble -d:release build")
  exec("./build/potholectl " & cleanArgs().join(" "))

after build:
  cpFile("pothole.conf",binDir & "/pothole.conf")

# Dependencies
requires "nim >= 2.0.0"
requires "nimcrypto >= 0.5.4"
requires "prologue >= 0.6.4"
requires "iniplus >= 0.2.2"
requires "db_connector >= 0.1.0"
# Package

version       = "0.0.2"
author        = "penguinite"
description   = "A lightweight and efficient microblogging server."
license       = "AGPL-3.0-or-later"
binDir        = "build"
bin           = @["pothole","potholectl"]
installDirs    = @["potholepkg"]
backend       = "c"

# Add different switches depending on if we are in debug/release mode
switch("app","console")
switch("opt","speed")
switch("stackTrace","on")
switch("mm","orc")

task clean, "Removes build folder if it exists":
  if dirExists(binDir):
    rmdir(binDir)
  if dirExists("static/"):
    rmdir("static/")
  if dirExists("uploads/"):
    rmdir("uploads/")

before build:
  if dirExists(binDir):
    rmdir(binDir)
  mkDir(binDir)
  if dirExists("static/"):
    rmdir("static/")
  if dirExists("uploads/"):
    rmdir("uploads/")

after build:
  cpFile("pothole.conf",binDir & "/pothole.conf")

# Dependencies
requires "nim >= 2.0.0"
requires "nimcrypto >= 0.5.4"
requires "prologue >= 0.6.4"
requires "iniplus >= 0.2.1"
requires "db_connector >= 0.1.0"
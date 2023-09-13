# Package

version       = "0.0.2"
author        = "xmoo"
description   = "A lightweight and efficient microblogging server."
license       = "AGPL-3.0-or-later"
srcDir        = "src"
binDir        = "build"
bin           = @["pothole"]
backend       = "c"

# Add different switches depending on if we are in debug/release mode
switch("app","console")
switch("opt","speed")
switch("stackTrace","on")

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

after build:
  cpFile("LICENSE",binDir & "/LICENSE")
  cpFile("pothole.conf",binDir & "/pothole.conf")

# Dependencies
requires "nim >= 1.6.10"
requires "nimcrypto >= 0.5.4"
requires "prologue >= 0.6.4"

const dbEngine{.strdefine.} = "sqlite"
when dbEngine == "sqlite":
  requires "tiny_sqlite >= 0.2.0"

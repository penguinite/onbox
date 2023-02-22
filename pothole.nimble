# Package

version       = "0.0.2"
author        = "xmoo"
description   = "A lightweight ActivityPub backend."
license       = "AGPL-3.0-or-later"
srcDir        = "src"
binDir        = "build"
bin           = @["pothole"]
backend       = "c"

var
  srcDir:string="src"
  rootDir:string="."
  buildDir:string="build"

# Add different switches depending on if we are in debug/release mode
when defined(debug):
  # Debug flags
  switch("app","console")
  switch("define","debug")
  switch("threads","on")
  switch("opt","speed")
  switch("stackTrace","on")
else:
  # Release flags
  switch("app","console")
  switch("define","release")
  switch("opt","speed")
  switch("threads","on")
  switch("stackTrace","on")

task clean, "Removes build folder if it exists":
  if dirExists(buildDir):
    rmdir(buildDir)
  if dirExists("static/"):
    rmdir("static/")
  if dirExists("uploads/"):
    rmdir("uploads/")
  if dirExists("blogs/"):
    rmdir("blogs/")

before build:
  if dirExists(buildDir):
    rmdir(buildDir)
  mkDir(buildDir)

after build:
  cpFile("LICENSE",buildDir & "/LICENSE")
  cpFile(rootDir & "/pothole.conf",buildDir & "/pothole.conf")


# Dependencies

requires "nim >= 1.6.10"
requires "prologue >= 0.6.4"
requires "nimcrypto >= 0.5.4"
# Package

hint("Processing", false) # Do not print annoying Hint: lines when building.
when defined(release):
    switch("hints","on")
else:
    switch("hints","off")

version       = "0.0.1"
author        = "quartz"
description   = "A lightweight ActivityPub backend."
license       = "AGPL-3.0-or-later"
srcDir        = "src"
binDir        = "build"
bin           = @["pothole"]
backend       = "c"

var
    srcDir:string="."
    buildDir:string="build"

# Add different switches depending on if we are in debug/release mode
when defined(debug):
    # Debug flags
    switch("app","console")
    switch("opt","speed")
    switch("checks","on")
    switch("stackTrace","on")
    switch("define","debug")
else:
    # Release flags
    switch("checks","on")
    switch("threads","on")
    switch("opt","speed")
    switch("app","console")
    switch("stackTrace","on")
    switch("define","release")


task clean, "Removes build folder if it exists":
    if dirExists(buildDir):
        rmdir(buildDir)

before build:
    if dirExists(buildDir):
        rmdir(buildDir)
    mkDir(buildDir)

after build:
    cpFile("LICENSE",buildDir & "/LICENSE")
    cpFile(srcDir & "/pothole.conf",buildDir & "/pothole.conf")


# Dependencies

requires "nim >= 1.6.10"
requires "prologue >= 0.6.4"
requires "nimcrypto >= 0.5.4"
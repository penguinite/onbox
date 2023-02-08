# Package

hint("Processing", false) # Do not print annoying Hint: lines when building.
when defined(release):
    switch("hints","on")
else:
    switch("hints","off")

version       = "0.0.2"
author        = "xmoo"
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
    switch("define","debug")
    switch("threads","on")
    switch("threadAnalysis","off")
    switch("opt","speed")
    switch("stackTrace","on")
    switch("define","useSqlite")
else:
    # Release flags
    switch("app","console")
    switch("define","release")
    switch("opt","speed")
    switch("threads","on")
    switch("threadAnalysis","off")    
    switch("stackTrace","on")
    switch("define","usePostgres")

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
requires "jester >= 0.5.0"
requires "nimcrypto >= 0.5.4"
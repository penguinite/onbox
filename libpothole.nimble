# Package

version       = "0.0.2"
author        = "xmoo"
description   = "Essential libraries for the Pothole server."
license       = "GPL-3.0-or-later"
skipDirs      = @["contrib"]

# Dependencies

task clean, "Cleans directory":
  if dirExists("htmldocs"):
    rmDir("htmldocs")

before docs:
  if dirExists("htmldocs"):
    rmDir("htmldocs")

var flags = "--project --warnings:off -d:dbEngine=docs --index:on libpothole.nim"
task docs, "Builds proper HTML documentation.":
  exec "nim doc " & flags
  rmFile("htmldocs/libpothole.html")



requires "nim >= 1.6.10"
requires "nimcrypto >= 0.5.4"
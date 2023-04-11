# Package

version       = "0.0.2"
author        = "xmoo"
description   = "Essential libraries for the Pothole server."
license       = "GPL-3.0-or-later"
skipDirs      = @["contrib"]

# Dependencies
#var version: string = "0.0.2" # Used for documentation building.
task clean, "Cleans directory":
  if dirExists("htmldocs"):
    rmDir("htmldocs")

before docs:
  if dirExists("htmldocs"):
    rmDir("htmldocs")

var flags = "--project --warnings:off -d:dbEngine=docs --git.url='https://gt.tilambda.zone/o/pothole/libpothole.git' --git.commit='v" & version & "' --index:on libpothole.nim"
task docs, "Builds proper HTML documentation.":
  exec "nim doc " & flags
  rmFile("htmldocs/libpothole.html")
  rmFile("htmldocs/nimdoc.out.css")
  cpFile("style.css","htmldocs/nimdoc.out.css")



requires "nim >= 1.6.10"
requires "nimcrypto >= 0.5.4"
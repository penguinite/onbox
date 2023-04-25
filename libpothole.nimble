# Package

version       = "0.0.2"
author        = "xmoo"
description   = "Essential libraries for the Pothole server."
license       = "GPL-3.0-or-later"
srcDir        = "src"

task clean, "Cleans directories":
  if dirExists("htmldocs"):
    rmDir("htmldocs")
  if dirExists(".sass-cache"):
    rmDir(".sass-cache")

before docs:
  if dirExists("htmldocs"):
    rmDir("htmldocs")
  if dirExists(".sass-cache"):
    rmDir(".sass-cache")

var flags = "--project --warnings:off -d:dbEngine=docs --git.url='https://gt.tilambda.zone/o/pothole/libpothole.git' --git.commit='v" & version & "' --index:on src/libpothole.nim"
task docs, "Builds proper HTML documentation.":
  exec "nim doc " & flags
  rmFile("htmldocs/libpothole.html")
  rmFile("htmldocs/dochack.js")

# Dependencies
requires "nim >= 1.6.10"
requires "nimcrypto >= 0.5.4"
requires "tiny_sqlite >= 0.2.0"

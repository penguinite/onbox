# Package

version       = "0.0.2"
author        = "xmoo"
description   = "Essential libraries for the Pothole server."
license       = "GPL-3.0-or-later"
srcDir        = "src"

when defined(iHaveMyOwnStuffThanks):
  before test:
    if fileExists("main.db"):
      rmFile("main.db")

task clean, "Cleans directories":
  if dirExists("htmldocs"):
    rmDir("htmldocs")
  if dirExists(".sass-cache"):
    rmDir(".sass-cache")

before docs:
  rmDir("htmldocs")
  rmDir("src/htmldocs")
  rmDir("src/libpothole/htmldocs")
  rmDir("src/libpothole/db/htmldocs")
  rmDir(".sass-cache")

var flags = "--warnings:off -d:dbEngine=docs --git.url='https://gt.tilambda.zone/o/pothole/libpothole.git' --git.commit='v" & version & "' --index:on --outdir:htmldocs "
task docs, "Builds proper HTML documentation.":
  for file in listFiles("src/libpothole"):
    exec "nim doc " & flags & file
  for file in listFiles("src/libpothole/db"):
    exec "nim doc " & flags & file
  exec "nim buildIndex -o:htmldocs/index.html htmldocs/"

# Dependencies
requires "nim >= 1.6.10"
requires "nimcrypto >= 0.5.4"

const dbEngine{.strdefine.} = "sqlite"
when dbEngine == "sqlite":
  requires "tiny_sqlite >= 0.2.0"

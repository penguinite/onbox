# Package

version       = "0.0.2"
author        = "penguinite"
description   = "A simple lightweight MastoAPI backend server"
license       = "AGPL-3.0-or-later"
bin           = @["onbox","onboxctl","onboxdev"]
srcDir        = "src"
binDir        = "build"
backend       = "cpp"

from std/os import commandLineParams
proc cleanArgs(name = "ctl"): seq[string] =
  commandLineParams()[commandLineParams().find(name) + 1..^1]

after clean:
  for dir in ["static/", "uploads/", binDir]:
    if dirExists(dir): rmDir(dir)

task all, "Builds everything with versioning embedded.":
  exec "nimble -d:version=\"" & version & " - " & gorgeEx("git rev-parse HEAD^")[0] & "\" -d:release build"

task ctl, "Shorthand for nimble run onboxctl":
  exec("nimble run onboxctl " & cleanArgs("ctl").join(" "))

task dev, "For running the internal developer tool.":
  exec("nimble run onboxctl " & cleanArgs("dev").join(" "))

task musl, "A task to build a binary linked with musl rather than glibc":
  exec("nimble build -d:musl -d:release --opt:speed")

after build:
  cpFile("onbox.conf",binDir & "/onbox.conf")
  cpFile("LICENSE", binDir & "/LICENSE")

# Dependencies
requires "nim >= 2.0.0"
requires "nimcrypto >= 0.5.4"
requires "rng >= 0.2.0"
requires "iniplus#d9509566d442f597547f8c8aa9bd7599c71a93ff"
requires "temple >= 0.2.3"
requires "db_connector >= 0.1.0"
requires "mummy >= 0.4.2"
requires "waterpark >= 0.1.7"
requires "cligen >= 1.7.3"
requires "smtp"
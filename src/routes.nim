# Copyright © Leo Gavilieau 2022-2023
# Licensed under the AGPL version 3 or later.
#
# Procedures and functions for Prologue routes.
# Storing them in pothole.nim or anywhere else
# would be a disaster.

# From Pothole
import assets, potcode

# From Nimble/other sources
import prologue

proc index*(ctx: Context) {.async.} =
  resp "<h1>Hello, Prologue!</h1>"

proc indexEXP*(ctx: Context = nil) {.async.} =
  echo(parseInternal(fetchStatic("index.html")))
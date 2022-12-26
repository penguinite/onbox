# Copyright © Louie Quartz 2022
# Licensed under the AGPL version 3 or later.
#
# Procedures and functions for Prologue routes.
# Storing them in pothole.nim or anywhere else
# would be a disaster.

# From Pothole
import conf

# From Nimble/other sources
import prologue

# Main homepage
proc index(ctx: Context) {.async.} =
  resp "Hello World!"

const patterns* = @[
  pattern("/", index)
]
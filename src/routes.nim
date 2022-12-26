# Copyright © Louie Quartz 2022
# Licensed under the AGPL version 3 or later.
#
# Procedures and functions for Prologue routes.
# Storing them in pothole.nim or anywhere else
# would be a disaster.

# From Pothole
#import conf
import lib
import data

# From standard libraries
from std/strutils import replace

# From Nimble/other sources
import prologue

# Main homepage
proc index*(ctx: Context) {.async.} =
  resp r"""<html><head></head><body><form action="/test" method="post"><input type="text" id="handle" name="handle" placeholder="handle"><br><br><input type="text" id="password" name="password" placeholder="password"><br><br><input type="text" id="name" name="name" placeholder="name"><br><br><input type="text" id="email" name="email" placeholder="email"><br><br><input type="text" id="bio" name="bio" placeholder="bio"><br><br><input type="submit"></form></body></html>"""

proc text*(ctx: Context) {.async.} =
  # Disallow dots, @ and colons.
  var
    handle = ctx.getPostParamsOption("handle").get()
    password = $ctx.getPostParamsOption("password").get()
    name = $ctx.getPostParamsOption("name").get()
    email = $ctx.getPostParamsOption("email").get()
    bio = $ctx.getPostParamsOption("bio").get()


  for x in localInvalidHandle:
    handle = handle.replace($x,"")

  var newuser: User = newUser(handle,password,true)
  newuser.name = name
  newuser.email = email
  newuser.bio = bio
  newuser = escapeUser(newuser)
  echo("Handle: ", newuser.handle)
  resp r" Hello World! " & $newuser
  
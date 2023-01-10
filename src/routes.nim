# Copyright © Louie Quartz 2022-2023
# Licensed under the AGPL version 3 or later.
#
# Procedures and functions for Prologue routes.
# Storing them in pothole.nim or anywhere else
# would be a disaster.

# From Pothole
import assets, web, db

# From standard libraries
from std/strutils import replace, contains

# From Nimble/other sources
import jester

router main:
  get "/":
    resp(web.indexPage())

  get "/users/@user":
    var user = @"user"
    # Assume the client has requested a user by handle
    # Let's do some basic validation first
    if not userHandleExists(user):
      resp(web.errorPage("No user found.",404))
    
    resp(web.userPage(getUserByHandle(user)))

  get "/css/style.css":
    resp(fetchStatic("style.css"))

  get "/favicon.ico":
    resp(Http200,"")
      

var potholeRouter* = main
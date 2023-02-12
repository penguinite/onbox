# Copyright © Leo Gavilieau 2022-2023
# Licensed under the AGPL version 3 or later.
#
# Procedures and functions for Prologue routes.
# Storing them in pothole.nim or anywhere else
# would be a disaster.

# From Pothole
import assets, db

# From Nimble/other sources
import jester

router main:
  get "/":
    resp "Ok"

  get "/users/@user":
    var user = @"user"
    
    # Assume the client has requested a user by handle
    # Let's do some basic validation first
    if not userHandleExists(user):
      resp(Http404, "No user found.",)
    
    resp(user)

  get "/css/style.css":
    resp(fetchStatic("style.css"))

  get "/favicon.ico":
    resp(Http200,"")
      

var potholeRouter* = main
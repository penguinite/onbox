# Copyright © Louie Quartz 2022
# Licensed under the AGPL version 3 or later.
#
# Procedures and functions for Prologue routes.
# Storing them in pothole.nim or anywhere else
# would be a disaster.

# From Pothole
#import conf
#import lib
#import data
import db

# From standard libraries
from std/strutils import replace, contains

# From Nimble/other sources
import jester

router main:
  get "/":
    resp("Welcome to Pothole!\n")
  get "/users/@user":
    var user = @"user"
    # Assume the client has requested a user by handle
    resp $getUserByHandle(user)
      

var potholeRouter* = main
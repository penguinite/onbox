# Copyright © Leo Gavilieau 2022-2023
# Licensed under the AGPL version 3 or later.
#
# This module is specifically for generating webpages.
# and user pages.
#

import conf
import assets
import strutils
import lib
import potcode
import db

proc indexPage*(): string =
  var page = assets.fetchStatic("index.html")
  return page.parseInternal()

proc errorPage*(error:string,code:int=0): string=
  var page = assets.fetchStatic("error.html")

  var error_sum = "";

  if code > 0:
    error_sum = $code

  return page.parseInternal()

# Let's try to make this fast and amazing.
# Firstly, read user's blog 
proc userPage*(user: User): string =
  var html = assets.fetchBlog(user.id)
  var posts = getPostsByUserHandle(user.handle,15)
  return html.parse(user, posts, "user")
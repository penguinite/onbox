# Copyright © Louie Quartz 2022
# Licensed under the AGPL version 3 or later.
#
# This module is specifically for generating webpages.
# and user pages.
#
# TODO: Find a better way of templating...
import conf
import assets
from strutils import replace, parseBool, parseInt
from lib import version

proc indexPage*(): string =
  var page = assets.fetchStatic("index.html")
  
  var instancedesc = conf.get("instance","description","You forgot to set the instance description in the configuration file!")
  
  var potholedesc = conf.get("web","description","This website runs Pothole, a lightweight ActivityPub server.")

  var potholever = "";
  if exists("web","show_version"):
    if parseBool(conf.get("web","show_version","false")) == true:
      potholever = "<p>Pothole version: " & lib.version & "</p>"

  page = page.replace("$(INSTANCE_DESC)",instancedesc)
  page = page.replace("$(POTHOLE_DESC)",potholedesc)
  page = page.replace("$(POTHOLE_VER)",potholever)
  return page

proc errorPage*(error:string,code:int=0): string=
  var page = assets.fetchStatic("error.html")

  var potholever, error_sum = "";

  if code > 0:
    error_sum = $code

  if exists("web","show_version"):
    if parseBool(conf.get("web","show_version","false")) == true:
      potholever = "<p>Pothole version: " & lib.version & "</p>"

  page = page.replace("$(ERROR_SUM)",error_sum)
  page = page.replace("$(ERROR)",error)
  page = page.replace("$(POTHOLE_VER)",potholever)
  return page

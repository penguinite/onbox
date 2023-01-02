# Copyright © Louie Quartz 2022
# Licensed under the AGPL version 3 or later.
#
## A module for fetching resources

import std/[os, tables, strutils]
import lib

# Main asset database.
# We wrap it in a procedure so Nim will immediately
# deallocate memory when a resource is fetched and done.
#
# This is for static assets
{.cast(gcsafe).}:
  when not defined(noEmbed):
    proc staticAsset(asset: string): string =
      const resources: Table[string,string] = {
        "index.html": staticRead("../assets/index.html"), # Main index page
        "style.css": staticRead("../assets/style.css"), # Styling for default user blog
        "user.html": staticRead("../assets/user.html"), # Default user blog
        "error.html": staticRead("../assets/error.html") # Error page
      }.toTable()
      return resources[asset]

  proc fetchStatic*(asset: string, data: string = ""): string =
    ## This procedure specifically tries to fetch a static resource.
    
    debug("Something trying to fetch static asset: " & asset, "assets.fetchStatic()")
    
    # Check if directory exists, if not, then create it!
    if not dirExists(staticFolder):
      createDir(staticFolder)
  
    # Split path to multiple tuples for easier processing.
    var (dir, filename, ext) = splitFile(asset)
  
    # Create any sub-directories if they exist
    if dir.contains("/"):
      if not dirExists(staticFolder & dir):
        createDir(staticFolder & dir)
  
    # Check if the file exists, if not then write it
    # If it does then great! Return its output
    if fileExists(staticFolder & asset):
      return readFile(staticFolder & asset)
    else:
      var trueAsset: string;
      if data == "":
        when not defined(noEmbed):
          trueAsset = staticAsset(filename & ext)
      else:
        trueAsset = data
      writeFile(staticFolder & asset,trueAsset)
      return trueAsset

  proc fetchUpload*(asset, id2: string, data: string = ""): string =
    ## This procedure specifically tries to fetch a user upload.
    debug("Something trying to fetch upload asset: " & asset & "by user (Id): " & id2, "assets.fetchUpload()")

    var id = id2
    id.add("/")
    
    # Check if uploads directory exists, if not, then create it!
    if not dirExists(uploadsFolder):
      createDir(uploadsFolder)
  
    # Check if user directory exists
    # Depending on if "data" is empty
    # we will either create a new directory
    # or error out
    if not dirExists(uploadsFolder & id):
      if data == "":
        error("User uploads directory does not exist for user id: " & id, )
      else:
        createDir(uploadsFolder & id)

    # Split path to multiple tuples for easier processing.
    var (dir, filename {.used.}, ext {.used.}) = splitFile(asset)
  
    # Create any sub-directories if they exist
    if dir.contains("/"):
      if not dirExists(uploadsFolder & id & dir):
        createDir(uploadsFolder & id & dir)
  
    # Check if the file exists, if not then write it
    # If it does then great! Return its output
    if fileExists(uploadsFolder & id & asset):
      return readFile(uploadsFolder & id & asset)
    else:
      var trueAsset: string;
      if data == "":
        discard # I am not sure what to do.
      else:
        trueAsset = data
      writeFile(uploadsFolder & id & asset,trueAsset)
      return trueAsset

# So... Blogs are just user themes basically.
# How blogs are stored and so on is documented in docs/DESIGN.md
# This procedure basically returns the directory where userPage will look for blog themes. It will double-check that all files exist and create them from embedded assets if they don't.
proc fetchBlog*(id2: string): string =
  debug("Something trying to fetch blogs from user " & id2, "assets.fetchBlog")
  if not dirExists(blogsFolder):
    createDir(blogsFolder)
  
  var id = id2
  id.add("/")

  if not dirExists(blogsFolder & id):
    createDir(blogsFolder & id)
  
  # Check for the three main files
  # and create them from embedded resources
  # if they do not exist
  # index.html is called user.html in staticAsset()
  # post.html is called post.html in staticAsset()
  # error.html is called user_error.html in staticAsset()
  var userDir = blogsFolder & id

  # index.html
  if not fileExists(userDir & "index.html"):
    when not defined(noEmbed):
      writeFile(userDir & "index.html", staticAsset("user.html"))
  
  # post.html
  if not fileExists(userDir & "post.html"):
    when not defined(noEmbed):
      writeFile(userDir & "post.html", staticAsset("post.html"))
  
  # error.html
  if not fileExists(userDir & "error.html"):
    when not defined(noEmbed):
      writeFile(userDir & "error.html", staticAsset("user_error.html"))
  
  return userDir
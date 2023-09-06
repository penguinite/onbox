# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This file is part of Pothole.
# 
# Pothole is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Pothole is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Pothole. If not, see <https://www.gnu.org/licenses/>. 
#
# assets.nim:
## This module basically acts as the assets store and it contains a quick templating library
## When compilling, we expect all of the built-in assets to be stored in the assets/ folder.
## On startup, we will load all of these and do some special operation to some modules.
## (Ie. index.html, the pothole main webpage, will need to be compiled with the built-in quick template library.)
import std/[tables, os]
import libpothole/[conf,lib]
import std/strutils except isEmptyOrWhitespace

when defined(noEmbeddingAssets):
  {.warning: "Not embedding assets is a really bad idea.".}
  proc getEmbeddedAsset*(fn: string): string = 
    debug "This build does not embed assets, thus getEmbeddedAsset does not work.", "assets.getEmbeddedAsset"
    error "Someone or something has attempted to fetch an asset with the filename " & fn & "\nUnfortunately assets were not embedded in this build, and so the only reasonable way out is to throw an error\nand force the administrator to setup the files properly for the next startup", "assets.getEmbeddedAsset"
else:
  func getEmbeddedAsset*(fn: string): string = 
    # We wrap it over a function so we dont immediately use up the RAM.
    const phLang{.strdefine.} = "en"
    const assets: Table[string, string] = {
      "index.html": staticRead("../assets/" & phLang & "/index.html"),
      "about.html": staticRead("../assets/" & phLang & "/about.html"),
      "style.css": staticRead("../assets/style.css") # CSS doesn't need language. Hopefully.
    }.toTable
    return assets[fn]

func renderTemplate*(input: string, vars: Table[string,string]): string =
  ## This function renders our template files. With simple string substitution.
  ## It's main benefit over using an external library is that it can be used in run-time quite easily.
  ## Nimja and nim-templates use macros which make it harder to pipe the output of a procedure to them. (For cleanliness's sake.)
  for line in input.splitLines:
    if "$" notin line:
      result.add(line & "\n")
      continue

    var 
      i = 0 # For storing where we are in the string 
      parseFlag = false # For checking whether we are currently parsing something or not.
      key = ""; # For storing the parsed key in.
      
    for ch in line:
      inc(i)

      if len(line) < i and not parseFlag:
        continue # Skip since line isnt large enough for string substitution (except if we are already parsing something in which case, do not skip. )
    
      if ch == '$' and not parseFlag:
        parseFlag = true # Set this to true so the later parts can start parsing. And then skip.
        continue

      if parseFlag:
        if ch == '$':
          parseFlag = false
          key = key.toLower() # Convert the key to lowercase for consistency.
          if vars.hasKey(key): # Check if it exists, and insert it into the result var
            result.add(vars[key])
          key = "" # Empty the key so previous output doesn't pollute everything else (This makes it easy to support multiple commands in one line.)
        else:
          key.add(ch)
        continue

      result.add(ch)
    result.add("\n")
    
  return result        

proc initUploads*(config:Table[string,string]): string =
  ## Initializes the upload folder by checking if the user has already defined where it should be
  ## and creating the folder if it doesn't exist.
  result = config.getStringOrDefault("folders", "uploads", "uploads/")
  
  if not result.endsWith("/"):
    result.add("/")

  if not dirExists(result):
    createDir(result)

  return result

proc initStatic*(config:Table[string,string]): string =
  ## Initializes the static folder by checking if the user has already defined where it should be
  ## and creating the folder if it doesn't exist.
  result = config.getStringOrDefault("folders", "static", "static/")
  if not result.endsWith("/"):
    result.add("/")

  if not dirExists(result):
    createDir(result)

  return result

proc getAsset*(folder, fn: string): string =
  # Get static asset
  if fileExists(folder & fn):
    return readAll(open(folder & fn))
  else:
    return getEmbeddedAsset(fn)

proc getUploadFilename*(folder, id, name: string): string =
  ## Returns the filename of the user upload.
  if not dirExists(folder & id):
    createDir(folder & id)

  if not fileExists(folder & id & "/" & name):
    return ""

  return folder & id & "/" & name

proc setAsset*(folder, id, name: string, data: openArray[byte]): bool =
  if not dirExists(folder & id):
    createDir(folder & id)
  
  if fileExists(folder & id & "/" & name):
    return false # File exists, Maybe scramble the name and retry dear client.

  try:
    var file = open(folder & id & "/" & name)
    file.write(data)
    file.close()
  except CatchableError as err:
    # Not being able to write to a file should be enough to error out and force
    # the operator to troubleshoot
    var caller = "assets.setAsset(writeStage)"
    debug "The user upload failed because of " & err.msg, caller
    debug "Saving data as data.bin for later troubleshooting",caller
    try:
      createDir(lib.globalCrashDir)
      var file = open(lib.globalCrashDir & "/data.bin")
      file.write(data)
      file.close()
    except:
      debug "The write failed? Okay, this environment is severely buggy. PLEASE INVESTIGATE BEFORE RE-LAUNCHING!", caller
    
    error "Failed to write user-upload file, debugging data is in " & lib.globalCrashDir,caller

  
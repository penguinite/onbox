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
import conf,lib
import std/strutils except isEmptyOrWhitespace, parseBool

when not defined(phNoEmbeddedAssets):
  const phLang{.strdefine.} = "en"
  const assets: Table[string, string] = {
    "index.html": staticRead("../assets/" & phLang & "/index.html"),
    "about.html": staticRead("../assets/" & phLang & "/about.html"),
    "signup.html": staticRead("../assets/" & phLang & "/signup.html"),
    "signup_disabled.html": staticRead("../assets/" & phLang & "/signup_disabled.html"),
    "signin.html": staticRead("../assets/" & phLang & "/signin.html"),
    "error.html": staticRead("../assets/" & phLang & "/error.html"),
    "success.html": staticRead("../assets/" & phLang & "/success.html"),
    "reaction.html": staticRead("../assets/" & phLang & "/reaction.html"),
    "user_post.html": staticRead("../assets/" & phLang & "/user_post.html"),
    "user.html": staticRead("../assets/" & phLang & "/user.html"),
    "style.css": staticRead("../assets/style.css") # CSS doesn't need language.
  }.toTable

  func getEmbeddedAsset*(fn: string): string =     
    return assets[fn]
else:
  {.warning: "Not embedding assets is a really bad idea.".}
  proc getEmbeddedAsset*(fn: string): string = 
    log "This build does not embed assets, thus getEmbeddedAsset does not work."
    log "The only reasonable way out is to throw an error and force the admin to setup the files properly"
    error "Couldn't retrieve asset with filename: ", fn

proc prepareNthLetter(s: string): string = 
  for ch in s:
    case ch:
    of ' ': result.add ' '
    else: result.add "<span>" & ch & "</span>"
  return result

func renderTemplate*(input: string, vars: Table[string,string]): string =
  ## This function renders our template files. With simple string substitution.
  ## It's main benefit over using an external library is that it can be used in run-time quite easily.
  ## Nimja and nim-templates use macros which make it harder to pipe the output of a procedure to them. (For cleanliness's sake.)
  var nth_letter = false
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

          # But first, let's check for if the key ends with "_nth_letter"
          # _nth_letter is an optional attribute that makes every character separated by a span tag.
          # This is for styling purposes, and it is entirely optional.
          if key.endsWith("_nth_letter"):
            key = key[0..^12]
            nth_letter = true

          if vars.hasKey(key): # Check if it exists, and insert it into the result var
            if nth_letter:
              result.add(prepareNthLetter(vars[key]))
              nth_letter = false
            else:
              result.add(vars[key])
          key = "" # Empty the key so previous output doesn't pollute everything else (This makes it easy to support multiple commands in one line.)
        else:
          key.add(ch)
        continue

      result.add(ch)
    result.add("\n")
    
  return result        

proc initUploads*(config: ConfigTable): string =
  ## Initializes the upload folder by checking if the user has already defined where it should be
  ## and creating the folder if it doesn't exist.
  result = config.getStringOrDefault("folders", "uploads", "uploads/")
  
  if not result.endsWith("/"):
    result.add("/")

  if not dirExists(result):
    createDir(result)

  return result

proc initTemplates*(config: ConfigTable): string =
  ## Initializes the templates folder by checking if the user has already defined where it should be
  ## and creating the folder if it doesn't exist.
  result = config.getStringOrDefault("folders", "templates", "templates/")
  if not result.endsWith("/"):
    result.add("/")

  if not dirExists(result):
    createDir(result)

  return result

proc initStatic*(config: ConfigTable): string =
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

proc getUpload*(cnf: ConfigTable, id, name: string): string =
  ## Get media asset.
  result.add(cnf.getStringOrDefault("storage","upload_uri",cnf.getString("instance","uri")))

  if result.endsWith("/"):
    # Remove slash at end if detected
    result = result[0..^2]
  
  if not cnf.exists("storage","upload_uri"):
    result.add("/media/")
  
  if id != "":
    result.add(id & "/" & name)
  else:
    result.add(name)

  return result

proc uploadExists*(cnf: ConfigTable, id, name: string): bool =
  return fileExists(getUpload(cnf, id, name))

proc getDefaultAvatar*(cnf: ConfigTable): string =
  result.add(cnf.getStringOrDefault("storage","upload_uri",cnf.getString("instance","uri")))

  if result.endsWith("/"):
    # Remove slash at end if detected
    result = result[0..^2]
  
  if not cnf.exists("storage","upload_uri"):
    result.add("/media/")

  return result & cnf.getStringOrDefault("storage","default_avatar_location","default_avatar.webp")

proc getAvatar*(cnf: ConfigTable, id: string): string =
  # TODO: Better avatar handling would be nice...
  for ext in @["jpg","jpeg","webp","png","gif","heic","heif"]:
    let file = getUpload(cnf, id, "avatar." & ext)
    if fileExists(file):
      return file
  return getDefaultAvatar(cnf)

proc getUploadFilename*(folder, id, name: string): string =
  ## Returns the filename of the user upload.
  if not dirExists(folder & id):
    createDir(folder & id)

  if not fileExists(folder & id & "/" & name):
    return ""

  return folder & id & "/" & name

proc writeReason(fn, reason: string) =
  ## Writes a user upload failure reason. Only used for setAsset
  const name = lib.globalCrashDir & "/failedUploads.log"
  try:
    var previousContent = ""
    if fileExists(name):
      previousContent = readFile(name)
    writeFile(lib.globalCrashDir & "/failedUploads.log", previousContent & "\n" & fn & ": " & reason)
  except CatchableError as err:
    log "Couldn't log user upload failure reason: ", err.msg


proc setAsset*(folder, id, name: string, data: openArray[byte]): bool =
  if not dirExists(folder & id):
    createDir(folder & id)
  
  if fileExists(folder & id & "/" & name):
    return false # File exists, Maybe scramble the name and retry dear client.

  try:
    writeFile(folder & id & "/" & name, data)
  except CatchableError as err:
    # In the past, pothole used to error out upon failing to write a user upload.
    # But I was worried about users being able to remotely crash pothole servers
    # By simply uploading a file. So I made them write the user data to a special
    # location along with the reason so that administrators can debug on their own.
    
    log "User upload failed: ", err.msg
    log "Saving to failsafe directory for future debugging."
    try:
      if not dirExists(lib.globalCrashDir): createDir(lib.globalCrashDir)
      if not dirExists(lib.globalCrashDir & "/failedUploads/"): createDir(lib.globalCrashDir & "/failedUploads/")

      let fName = "$#/failedUploads/$#-$#-$#.bin" % [lib.globalCrashDir, folder, id, name]
      # Storing reason for failed upload
      writeReason(fName, err.msg)
      # Writing user-uploaded data
      writeFile(fName, data)
    except CatchableError as err:
      log "Write to failsafe directory failed: ", err.msg
    
    return false # Let client come up with some reason as to why it failed.

  
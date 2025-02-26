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
import std/os, pothole/[conf, lib]
import std/strutils except isEmptyOrWhitespace, parseBool

proc initUploads*(config: ConfigTable): string =
  ## Initializes the upload folder by checking if the user has already defined where it should be
  ## and creating the folder if it doesn't exist.
  result = config.getStringOrDefault("folders", "uploads", "uploads/")
  
  if not result.endsWith("/"):
    result.add("/")

  if not dirExists(result):
    createDir(result)

  return result

proc getAsset*(fn: string): string =
  # Get static asset
  const table = {
    "oauth.html": staticRead("../assets/oauth.html"),
    "signin.html": staticRead("../assets/signin.html"),
    "generic.html": staticRead("../assets/generic.html"),
    "home.html": staticRead("../assets/home.html"),
    "style.css": staticRead("../assets/style.css")
  }.toTable
  return table[fn]

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

proc getHeader*(cnf: ConfigTable, id: string): string =
  # TODO: Implement this
  return


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
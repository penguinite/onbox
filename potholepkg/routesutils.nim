# From potholepkg or pothole's server codebase
import lib,conf,database,assets,user,crypto

# From stdlib
import std/[tables, options]
import std/strutils except isEmptyOrWhitespace, parseBool

# From nimble/other sources
import prologue

proc preRouteInit*() =
  if config.isNil(): config = setup(getConfigFilename())
  if staticFolder == "": staticFolder = initStatic(config)
  db = init(config) # TODO: Fix database.isNil()
  
template response*(body: string, code = Http200, version = HttpVer11) = 
  ## This is just prologue's `resp` with one extra addition
  ## A return statement so that the rest of the code doesn't get executed when we don't want it to.
  resp body, code, version
  return

proc renderError*(error: string): string =
  # One liner to generate an error webpage.
  {.gcsafe.}:
    return renderTemplate(
        getAsset(staticFolder,"error.html"),
      {"error": error}.toTable,
    )

proc renderError*(error, fn: string): string =
  {.gcsafe.}:
    var table = templateTable
  table["result"] = "<div class=\"error\"><p>" & error & "</p></div>"

  {.gcsafe.}:
    return renderTemplate(
        getAsset(staticFolder, fn),
      table
    )

proc renderSuccess*(str: string): string =
  # One liner to generate a "Success!" webpage.
  {.gcsafe.}:
    return renderTemplate(
        getAsset(staticFolder, "success.html"),
      {"result": str}.toTable,
    )

proc renderSuccess*(msg, fn: string): string =
  {.gcsafe.}:
    var table = templateTable
  table["result"] = "<div class=\"success\"><p>" & msg & "</p></div>"
  {.gcsafe.}:
    return renderTemplate(
      getAsset(staticFolder, fn),
      table
    )

proc isValidQueryParam*(req: Request, param: string): bool =
  if isEmptyOrWhitespace(req.queryParams[param]):
    return false
  return true

proc decodeMultipartEx*(req: Request): Table[string, string] {.raises: [MummyError].} =
  ## Mummy's built-in Multipart handling is stupid and difficult to use.
  ## So this procedure takes a Mummy request object and transforms it into a lovely Table[string, string]
  ## Note: Empty or whitespace-only data (Anything that will be thrown out by lib.isEmptyOrWhitespace) will not be added into the table.
  ## TODO: Maybe investigate what entry.filename is supposed to be? We throw that away as of now.
  let entries = req.decodeMultipart()
  for entry in entries:
    if isEmptyOrWhitespace(entry.name):
      continue # Skip if entry name is mostly empty
    if isNone(entry.data):
      continue # Skip if entry data isn't provided
    let
      (start, last) = entry.data.get
      data = req.body[start .. last]

    if isEmptyOrWhitespace(data):
      continue
    
    result[entry.name] = data
  return result
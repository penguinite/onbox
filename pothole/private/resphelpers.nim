import pothole/assets
import std/[tables, macros, json]
import mummy, temple

# Oh dear god... A "Template Object" pool.
# TODO: It's obvious why *this* needs refactoring, so in the future, please do that.
type
  TemplateObj* = object
    staticFolder*: string
    templatesFolder*: string
    table*: Table[string, string]

proc createHeaders*(a: string): HttpHeaders =
  result["Content-Type"] = a
  return

macro respJsonError*(msg: string, code = 400, headers = createHeaders("application/json")) =
  var req = ident"req"

  result = quote do:
    `req`.respond(
      `code`, `headers`, $(%*{"error": `msg`})
    )
    return

macro respJson*(msg: string, code = 200, headers = createHeaders("application/json")) =
  var req = ident"req"

  result = quote do:
    `req`.respond(
      `code`, `headers`, `msg`
    )
    return

proc render*(obj: TemplateObj, fn: string, extras: openArray[(string,string)] = @[]): string =
  ## Renders the "fn" template file using the usual template table + any extras provided by the extras parameter
  var table = obj.table

  for key, val in extras.items:
    table[key] = val

  return templateify(
    getAsset(obj.templatesFolder, fn),
    table
  )

proc renderError*(obj: TemplateObj, msg: string, fn: string = "generic.html"): string =
  return obj.render(
    fn,
    {
      "message_type": "error",
      "title": "Error!",
      "message": msg
    }
  )


proc renderSuccess*(obj: TemplateObj, msg: string, fn: string = "generic.html"): string =
  return obj.render(
    fn,
    {
      "message_type": "success",
      "title": "Success!",
      "message": msg
    }
  )

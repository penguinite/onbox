import std/[tables, macros, json]
import mummy

# Oh dear god... A "Template Object"
# TODO: It's obvious why *this* needs changing, so in the future, please do that.
type
  TemplateObj* = object
    staticFolder*: string
    templatesFolder*: string
    realURL*: string
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
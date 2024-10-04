import quark/strextra
import std/json

proc hasValidStrKey*(j: JsonNode, k: string): bool =
  if not j.hasKey(k):
    return false

  if j[k].kind != JString:
    return false

  try:
    if j[k].getStr().isEmptyOrWhitespace():
      return false
  except:
    return false

  return true


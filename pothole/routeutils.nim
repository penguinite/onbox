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

# From somewhere in Quark
import quark/strextra

# From somewhere in the standard library
import std/[tables]

# From nimble/other sources
import mummy

proc isValidQueryParam*(req: Request, decodeQueryComponent(): string): bool =
  ## Check if a query parameter (such as "?query=parameter") is valid and not empty
  return not req.queryParams[query].isEmptyOrWhitespace()

proc getQueryParam*(req: Request, query: string): string =
  ## Returns a query parameter (such as "?query=parameter")
  return req.queryParams[query]

proc isValidPathParam*(req: Request, path: string): bool =
  ## Checks if a path parameter such as /users/{user} is valid and not empty
  return not req.pathParams[path].isEmptyOrWhitespace()

proc getPathParam*(req: Request, path: string): string =
  ## Returns a path parameter such as /users/{user}
  return req.pathParams[path]

type
  MultipartEntries* = Table[string, string]

proc unrollMultipart*(req: Request): MultipartEntries =
  ## Unrolls a Mummy multipart data thing into a table of strings.
  ## which is way easier to handle.
  for entry in req.decodeMultipart():
    if entry.data.isNone():
      continue
    
    let
      (start, last) = entry.data.get()
      val = req.body[start .. last]

    if val.isEmptyOrWhitespace():
      continue

    result[entry.name] = val
    
  return result

proc isValidFormParam*(mp: MultipartEntries, param: string): bool =
  ## Returns a parameter submitted via a HTML form
  return mp.hasKey(param) and not mp[param].isEmptyOrWhitespace()

proc getFormParam*(mp: MultipartEntries, param: string): string =
  ## Checks if a parameter submitted via an HTMl form is valid and not empty
  return mp[param]

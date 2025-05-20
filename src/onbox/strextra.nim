# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This file is part of Onbox. Specifically, the Quark repository.
# 
# Onbox is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Onbox is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Onbox. If not, see <https://www.gnu.org/licenses/>. 
#
# strextra.nim:
## This module provides complementary string handling functions,
## such as functions for converting various datatypes to and from
## strings (for, say, database-compatability) or it might provide
## some new functionality not in std/strutils but too useless by itself
## to justify a new module.
## 
## This module is basically meant to be a complementary module to std/strutils

# From the standard library
import std/[strutils, json], mummy

func smartSplit*(s: string, specialChar: char = '&'): seq[string] =
  ## A split function that is both aware of quotes and backslashes.
  ## Aware, as in, it won't split if it sees the specialCharacter surrounded by quotes, or backslashed.
  ## 
  ## Used in (and was originally written for) `onbox/routeutils.nim:unrollForm()`
  var
    quoted, backslash = false
    tmp = ""
  for ch in s:
    case ch:
    of '\\':
      # If a double backslash has been detected then just
      # insert a backslash into tmp and set backslash to false
      if backslash:
        backslash = false
        tmp.add(ch)
      else:
        # otherwise, set backslash to true
        backslash = true
    of '"', '\'': # Note: If someone mixes and matches quotes in a form body then we're fucked but it doesn't matter either way.
      # If a backslash was previously detected then
      # add double quotes to tmp instead of toggling the quoted flag
      if backslash:
        tmp.add(ch)
        backslash = false
      else:
        if quoted: quoted = false
        else: quoted = true      
    else:
      # if the character we are currently parsing is the special character then
      # check we're not in backslash or quote mode, and if not
      # then finally split.
      if ch == specialChar:
        if backslash or quoted:
          tmp.add(ch)
          continue
        result.add(tmp)
        tmp = ""
        continue
      
      # otherwise, just check for backslash and add it to tmp if it isn't backslashed.
      if backslash:
        continue
      tmp.add(ch)
  
  # If tmp is not empty then split once more!
  # This is to make sure that we're not missing any data.
  # And that's it!
  if tmp != "":
    result.add(tmp)

func htmlEscape*(pre_s: string): string =
  ## Very basic HTML escaping function.
  var s = pre_s
  if s.startsWith("javascript:"):
    s = s[11..^1]
  if s.startsWith("script:"):
    s = s[7..^1]
  if s.startsWith("java:"):
    s = s[5..^1]

  for ch in s:
    case ch:
    of '<':
      result.add("&lt;")
    of '>':
      result.add("&gt;")
    else:
      result.add(ch)

proc parseRecipients*(data: string): seq[(string, string)] =
  ## Returns a set of handles (name and optionally, a domain)
  ## This procedure was designed with plain-text posts in mind.
  runnableExamples:
    assert parseRecipients("Hi @john@example.com!")[0] == ("john","example.com")
  type State = enum
    None, Handle, Domain

  var
    s = None
    handle, domain = ""

  for ch in data:
    if ch == '@':
      case s:
      of None: s = Handle
      of Handle: s = Domain
      of Domain: s = None
      continue

    if ch in {' ','?','%','&','/','(',')','[',']','{','}','"','\'','!','$'}:
      s = None
      if handle != "":
        result.add((handle, domain))
        handle = ""
        domain = ""
    else:
      case s:
      of None: continue
      of Handle: handle.add(ch)
      of Domain: domain.add(ch)
  
  # One last check
  if handle != "":
    result.add((handle, domain))

proc parseHashtags*(data: string): seq[string] =
  ## Returns a set of handles (name + optionally, domain)
  ## This proc was designed with plain-text posts in mind.
  var
    flag = false
    tag = ""

  for ch in data:
    case ch:
    of '#': flag = true
    of ' ':
      if tag != "":
        result.add(tag)
        flag = false
        tag = ""
    else:
      if flag: tag.add(ch)
  
  # One last check
  if tag != "":
    result.add(tag)

# Yes, this procedure returns a string but it is about parsing text.
# (And also way too big to include in routes.nim)
proc formToJson*(data: string): JsonNode =
  ## Converts normal form data encoded in `application/x-www-form-urlencoded`
  ## into a JsonNode.
  ## 
  ## Use of this procedure is encouraged to make code cleaner.
  ## 
  ## Note: The resulting JsonNode consists mostly of strings.
  ## Thus, you might need to specifically convert boolean values
  ## before passing it onto later code.
  runnableExamples:
    var json: JsonNode
    case contentType:
    of "application/x-www-form-urlencoded":
      json = formToJson(req.body)
    of "application/json":
      json = parseJson(req.body)
    else:
      raise newException(OSError, "Unknown Content-Type")
  
  proc parseObjKey(s: string): (string, string) =
    var flag = false
    for ch in s:
      case ch:
      of '[': flag = true
      of ']': break
      else:
        case flag:
        of true: result[1].add(ch)
        of false: result[0].add(ch)


  result = newJObject()
  for item in data.smartSplit('&'):
    if '=' notin item:
      continue # Invalid entry: Does not have equal sign.

    let pair = item.smartSplit('=') # let's just re-use this amazing function.

    if len(pair) != 2:
      continue # Invalid entry: Does not have precisely two parts.

    var
      key = pair[0].decodeQueryComponent()
      val = pair[1].decodeQueryComponent()
    
    if key.isEmptyOrWhitespace() or val.isEmptyOrWhitespace():
      continue # Invalid entry: Key or val (or both) are empty or whitespace. Invalid.
    
    # Parse the key portion.
    
    # Check if a key is an array
    if key.endsWith("[]"):
      if not result.hasKey(key[0..^3]):
        result[key[0..^3]] = newJArray()
      if result[key[0..^3]].kind != JArray:
        continue # Invalid JsonNode kind
      result[key[0..^3]].elems.add(newJString(val))
      continue
    
    # Check if a key is an object
    if key.endsWith("]"):
      # source[privacy]=public&source[language]=en 
      # {
      #  "source": "public",
      #  "language": "en"
      # }

      # TODO: parseObjKey() returns only a tuple
      # Keys in the future such as "post[account][id]" are not supported
      # For now, this'll work but it's not a good idea.
      let obj = parseObjKey(key)
      if not result.hasKey(obj[0]):
        result[obj[0]] = newJObject()
      if result[obj[0]].kind != JObject:
        continue # Invalid JsonNode kind
      result[obj[0]][obj[1]] = newJString(val)
      continue
  
    result[key] = newJString(val)
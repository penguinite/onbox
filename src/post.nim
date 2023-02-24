# Copyright © Leo Gavilieau 2022-2023
# Licensed under AGPL version 3 or later
#
# post.nim:
## Various functions for handling posts.
## The actual data types are stored in lib.nim
## Database-related functions are stored in db.nim

# From Pothole
import lib, crypto

# From Nim's standard library
import std/strutils except isEmptyOrWhitespace
import std/times

proc escape*(olduser: Post): Post =
  ## A procedure to escape a Post object
  var post = olduser[] # De-reference at the start

  for key,val in post.fieldPairs:
    when typeof(val) is bool:
      post.get(key) = val

    when typeof(val) is string:
      post.get(key) = escape(val)

    when typeof(val) is seq[string]:
      var newseq: seq[string] = @[]
      for x in val:
        newseq.add(escape(x))
      post.get(key) = newseq

  new(result); result[] = post # Re-reference at the end
  return result

proc unescape*(oldpost: Post): Post =
  ## A procedure to unescape a Post object
  var post = oldpost[] # De-reference at the start

  for key,val in post.fieldPairs:
    when typeof(val) is bool:
      post.get(key) = val

    when typeof(val) is string:
      post.get(key) = unescape(val,"","")

    when typeof(val) is seq[string]:
      var newseq: seq[string] = @[]
      for x in val:
        newseq.add(unescape(x,"",""))
      post.get(key) = newseq

  new(result); result[] = post # Re-reference at the end
  return result

proc newPost*(sender,replyto,content: string, recipients: seq[string] = @[], local: bool = false, written: string = "", contexts: seq[string] = @[]): Post =
  var post: Post = Post()
  if isEmptyOrWhitespace(sender) or isEmptyOrWhitespace(content):
    error("Missing critical fields for post.","data.newPost")

  # Generate post id
  post.id = randomString()
  
  # Just do this stuff...
  post.sender = sender
  post.recipients = recipients
  post.local = local
  post.content = content

  if isEmptyOrWhitespace(replyto):
    post.replyto = ""
  else:
    post.replyto = replyto

  if isEmptyOrWhitespace(written):
    post.written = $(now().utc) # Writing time-related code is always going to be messy...
  else:
    post.written = written

  return post

func `$`*(obj: Post): string =
  ## Turns a Post object into a human-readable string
  result.add("[")
  for key,val in obj[].fieldPairs:
    result.add("\"" & key & "\": \"" & $val & "\",")
  result = result[0 .. len(result) - 2]
  result.add("]")
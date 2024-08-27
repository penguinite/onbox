import std/[tables, times]
from db_connector/db_postgres import dbQuote

type
  PostPrivacyLevel* = enum
    Public, Unlisted, FollowersOnly, Private

  PostContentType* = enum
    Text, Poll, Media, Card

  PostContent* = object of RootObj
    case kind*: PostContentType
    of Text:
      text*: string # The text
    of Poll:
      id*: string # The poll ID
      question*: string # The question that was asked for the poll
      options*: Table[string, seq[string]] # Key: Option, Val: List of users who voted for that option
      total_votes*: int # Total number of votes
    of Media:
      media_id*: string
    else:
      discard

  PostRevision* = object of PostContent
    published*: DateTime # The timestamp of when then Post was last edited

  Post* = object
    id*: string # A unique id.
    recipients*: seq[string] # A sequence of recipient's handles.
    sender*: string # Basically, the person sending the message (Or more specifically, their ID.)
    replyto*: string # Resource/Post person was replying to,  
    content*: seq[PostContent] # The actual content of the post
    written*: DateTime # A timestamp of when the Post was created
    modified*: bool # A boolean indicating whether the Post was edited or not.
    local*:bool # A boolean indicating whether or not the post came from the local server or external servers
    client*: string # A string containing the client id used for writing this post.
    level*: PostPrivacyLevel # The privacy level of the post
    reactions*: Table[string, seq[string]] # A sequence of reactions this post has.
    boosts*: Table[string, seq[string]] # A sequence of id's that have boosted this post. (Along with what level)
    revisions*: seq[PostRevision] # A sequence of past revisions, this is basically copies of post.content


proc toDbString*[T](sequence: seq[T]): string =
  for item in sequence:
    result.add(dbQuote($(sequence)))
    result.add(",")
  if len(result) > 0:
    result = result[0..^2]
  return "{" & result & "}"

proc fromDbToSeq*(old: string): seq[string] =
  var str = old[1..^2]
  for ch in str:
    

  var old = 

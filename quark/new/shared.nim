import std/[tables, times]

type
  PostPrivacyLevel* = enum
    Public, Unlisted, FollowersOnly, Private

  PostContentType* = enum
    Text = "0", Poll = "1", Media = "2", Card = "3", Unknown = "9999"

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
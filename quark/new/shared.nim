import std/[tables, times]

type
  PostPrivacyLevel* = enum
    Public, Unlisted, FollowersOnly, Private

  PostContentType* = enum
    Text = "0", Poll = "1", Media = "2", Card = "3", Unknown = "9999"

  PostContent* = object of RootObj
    case kind*: PostContentType
    of Text:
      published*: DateTime # The timestamp of when then Post was last edited
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

  KDF* = enum
    PBKDF_HMAC_SHA512 = "1"

  # What type of user, this is directly from ActivityStreams.
  UserType* = enum
    Person, Application, Organization, Group, Service

  # User data type.
  User* = object
    id*: string # An unique that represents the actual user
    kind*: UserType # What type of User this is. (Used for outgoing Activities)
    handle*: string # A string containing the user's actual username 
    name*: string # A string containing the user's display name
    local*: bool # A boolean indicating if this user is from this instance 
    email*: string # A string containing the user's email
    bio*: string # A string containing the user's biography
    password*: string # A string to store a hashed + salted password 
    salt*: string # The actual salt with which to hash the password.
    kdf*: KDF # Key derivation function version
    admin*: bool # A boolean indicating if the user is an admin.
    moderator*: bool # A boolean indicating if the user is a moderator.
    is_frozen*: bool # A boolean indicating if the user is frozen/banned.
    is_verified*: bool # A boolean indicating if the user's email has been verified. 
    is_approved*: bool # A boolean indicating if the user hs been approved by an administrator
    discoverable*: bool # A boolean indicating if the user is discoverable
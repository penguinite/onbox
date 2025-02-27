# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
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
#
# lib.nim:
## This module contains procedures, templates, constants and other data
## to be shared across Pothole, or that is used many times across many places.
## 
## Some of the stuff included here is the globalCrashDir constant for post-mortem debugging
## API compatability level constant, source repo URL constant and log + error procedures.

# Originally, the plan was to retire this module ASAP and move the data here elsewhere
# But increasingly, it doesn't look like this module will be retired.
# Instead, we have yet another "shared" module (quark/shared)
# So, TODO: Merge quark/shared and pothole/lib or get rid of both.

# Useful data
const
  globalCrashDir* {.strdefine.}: string = "CAR_CRASHED_INTO_POTHOLE" ## Which folder to use when storing data for post-mortem debugging in crashes.
  phVersion* {.strdefine.}: string = "0.0.2" ## To customize the version, compile with the option: `-d:phVersion=whatever`
  phMastoCompat* {.strdefine.}: string = "wip" ## The level of API compatability, this option doesn't do anything. It's just reported in the API.
  phSourceUrl* {.strdefine.}: string = "https://github.com/penguinite/pothole" ## To customize the source URL, compile with the option: `-d:phSourceUrl="Link"`

import std/[strutils, tables, times]
  
template log*(str: varargs[string, `$`]) =
  stdout.write("[$#] ($#:$#): $#\n" % [now().utc.format("yyyy-mm-dd hh:mm:ss"), instantiationInfo().filename, $instantiationInfo().line, str.join])

template error*(str: varargs[string, `$`]) =
  ## Exits the program with an error messages and a stacktrace.
  stderr.write("\n!ERROR! [$#] ($#:$#): $#\n" % [now().utc.format("yyyy-mm-dd hh:mm:ss"), instantiationInfo().filename, $instantiationInfo().line, str.join])
  stderr.write("\nPrinting stacktrace...\n")
  writeStackTrace()  
  quit(1)

type
  FollowStatus* = enum
    NoFollowRequest, PendingFollowRequest, AcceptedFollowRequest

  PostPrivacyLevel* = enum
    Public = "0"
    Unlisted = "1"
    FollowersOnly = "2"
    Limited = "3"
    Private = "4"

  PostContentType* = enum
    Text = "0"
    Poll = "1"
    Media = "2"

  PostContent* = object of RootObj
    case kind*: PostContentType
    of Text:
      txt_published*: DateTime # The timestamp of when then Post was last edited
      txt_format*: int # The format that the text is written in.
      text*: string # The text
    of Poll:
      id*: string # The poll ID
      votes*: CountTable[string] # How many votes each option has.
      total_votes*: int # Total number of votes
      multi_choice*: bool # If the poll is a multi-choice poll or not.
      expiration*: DateTime # How long until the poll is dead and no one can post in it.
    of Media:
      media_id*: string

  Post* = object
    modified*: bool # A boolean indicating whether the Post was edited or not.
    local*:bool # A boolean indicating whether or not the post came from the local server or external servers
    id*: string # A unique id.
    sender*: string # Basically, the person sending the message (Or more specifically, their ID.)
    replyto*: string # Resource/Post person was replying to,  
    client*: string # A string containing the client id used for writing this post.
    tags*: seq[string] # Set of hashtags used
    recipients*: seq[string] # A sequence of recipient's handles.
    level*: PostPrivacyLevel # The privacy level of the post
    written*: DateTime # A timestamp of when the Post was created
    content*: seq[PostContent] # The actual content of the post
    reactions*: Table[string, seq[string]] # A sequence of reactions this post has.
    boosts*: Table[string, seq[string]] # A sequence of id's that have boosted this post. (Along with what level)

  KDF* = enum
    PBKDF_HMAC_SHA512 = "1"

  # What type of user, this is directly from ActivityStreams.
  UserType* = enum
    Person, Application, Organization, Group, Service

  ProfileField* = object
    key*, val*: string
    verified*: bool
    verified_at*: DateTime

  # User data type.
  User* = object
    id*: string # An unique ID that represents the actual user
    roles*: seq[int] # Roles associated with this user
    handle*: string # A string containing the user's actual username 
    domain*: string # If a user is federated, then this string will contain their residency. For local users this is empty.
    name*: string # A string containing the user's display name
    local*: bool # A boolean indicating if this user is from this instance 
    discoverable*: bool # A boolean indicating if the user is discoverable
    email_verified*: bool # A boolean indicating if the user has verified their email
    email*: string # A string containing the user's email
    bio*: string # A string containing the user's biography
    password*: string # A string to store a hashed + salted password 
    salt*: string # The actual salt with which to hash the password.
    kdf*: KDF # Key derivation function version
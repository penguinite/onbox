# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
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
# src/quark/shared.nim:
## This module contains important type definitions for User, Post, PostContent and anything else we use.
## 
## Why aren't they stored in their respective modules?
## Well the issue is that it would introduce cyclic dependencies.
## For example, let's say you have a procedure in quark/posts which needs to access user data somehow.
## The preferred thing to do, for readability reasons, is to import quark/users and to just use the proc you need.
## But then, when we need to write a proc in quark/users which needs to access post data, we can't!

## TODO: Find a way to put each type in its own module.

import std/[tables, times]

type
  PostPrivacyLevel* = enum
    Public, Unlisted, FollowersOnly, Limited, Private

  PostContentType* = enum
    Text = "0"
    Poll = "1"
    Media = "2"
    Tag = "4"

  PostContent* = object of RootObj
    case kind*: PostContentType
    of Text:
      published*: DateTime # The timestamp of when then Post was last edited
      text*: string # The text
      format*: string # The format that the text is written in.
    of Tag:
      tag_used*: string # The name of the hashtag being used (Part after the # symbol)
      tag_date*: DateTime # The date the hashtag was added
    of Poll:
      id*: string # The poll ID
      votes*: CountTable[string] # How many votes each option has.
      total_votes*: int # Total number of votes
      multi_choice*: bool # If the poll is a multi-choice poll or not.
      expiration*: DateTime # How long until the poll is dead and no one can post in it.
    of Media:
      media_id*: string

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
    domain*: string # If a user is federated, then this string will contain their residency. For local users this is empty.
    name*: string # A string containing the user's display name
    local*: bool # A boolean indicating if this user is from this instance 
    email*: string # A string containing the user's email
    bio*: string # A string containing the user's biography
    password*: string # A string to store a hashed + salted password 
    salt*: string # The actual salt with which to hash the password.
    kdf*: KDF # Key derivation function version
    admin*: bool # A boolean indicating if the user is an admin.
    moderator*: bool # A boolean indicating if the user is a moderator.
    discoverable*: bool # A boolean indicating if the user is discoverable
    is_frozen*: bool # A boolean indicating if the user is frozen/banned.
    is_verified*: bool # A boolean indicating if the user's email has been verified. 
    is_approved*: bool # A boolean indicating if the user hs been approved by an administrator
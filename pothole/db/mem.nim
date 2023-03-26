# Copyright © Leo Gavilieau 2022-2023
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0 or later. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# db/mem.nim:
## A database backend that uses the host's memory
## This is not recommended for production builds.
## Please do not use this

import ../lib

proc init*(noSchemaCheck:bool = false): bool =
  ## Do any initialization work.
  return true

proc uninit*(): bool =
  ## Uninitialize the database.
  ## Or close it basically...
  return true

proc addUser*(user: User): User = 
  ## Add a user to the database
  return user

proc userIdExists*(id:string): bool =
  ## A procedure to check if a user exists by id
  return false

proc userHandleExists*(handle:string): bool =
  ## A procedure to check if a user exists by handle
  return false

proc getUserById*(id: string): User =
  ## Retrieve a user from the database using their id
  return User()

proc getUserByHandle*(handle: string): User =
  ## Retrieve a user from the database using their handle
  return User()

proc updateUserByHandle*(handle, column, value: string): bool =
  ## A procedure to update the user by their handle
  return true

proc updateUserById*(id, column, value: string): bool = 
  ## A procedure to update the user by their ID
  return true

proc getIdFromHandle*(handle: string): string =
  ## A function to convert a user handle to an id.
  return ""

proc getHandleFromId*(id: string): string =
  ## A function to convert a  id to a handle.
  return ""

proc addPost*(post: Post): Post =
  ## A function add a post into the database
  return Post()

proc postIdExists*(id: string): bool =
  ## A function to see if a post id exists in the database
  return false

proc updatePostById*(id, column, value: string): bool =
  ## A procedure to update a post using it's id
  return true

proc getPostById*(id: string): Post =
  ## A procedure to get a post object from the db using its id
  return Post()

proc getPostsByUserHandle*(handle:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts from the db using the users handle
  return @[Post()]  

proc getPostsByUserId*(id:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts from the db using the users id
  return @[Post()]
  
proc getAdmins*(limit: int = 5): seq[string] =
  ## A procedure that returns the usernames of all administrators.
  return @[]

proc getTotalUsers*(): int =
  ## A procedure to get the total number of local users.
  return 0

proc getTotalPosts*(): int =
  ## A procedure to get the total number of local posts.
  return 0
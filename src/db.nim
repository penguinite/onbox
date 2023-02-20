# Copyright © Leo Gavilieau 2022-2023
# Licensed under the AGPL version 3 or later.
#
# db.nim: 
## A compile-time wrapper for your actual database backend.
## By default, debug compilation will use sqlite and production compilation will use postgres.
## But this can be configured by supplying -d:dbEngine=DATABASE_BACKEND to the nimble command.
## (Of course, replace DATABASE_BACKEND with a file from the db/ folder without the extension)
## So to use sqlite, you would supply: -d:dbEngine=sqlite
## or postgres: -d:dbEngine=postgres
## 
## NOTE: MAKE SURE TO SUPPLY THE DBENGINE ARGUMENT *BEFORE* THE TASK IS SUPPLIED
## Like so: nimble -d:dbEngine=DB_BACKEND build
## and NOT: nimble build -d:dbEngine=DB_BACKEND

#! Note to my future employer: Please don't look at this code.
# I really wanted to add support for multiple databases,
# and a choice like that doesn't come with its own consequences.
# I had to sacrifice code readability for this.

from lib import User, Post

{.experimental: "codeReordering".}

when defined(dbEngine):
  const dbEngine {.strdefine.}: string = ""
else:
  when defined(release):
    const dbEngine = "sqlite" # The postgres database backend is in development.
  else:
    const dbEngine = "sqlite"

{.warning: "Using " & dbEngine & " as database engine.".}

# Add your database backends here.
# This is the really ugly part. The rest is fine.
when dbEngine == "sqlite":
  import db/sqlite
when dbEngine == "postgres":
  import db/postgres
when dbEngine == "skeleton":
  import db/skeleton
when dbEngine == "mem":
  import db/mem

# These warnings would overwhelm the build output.
# And they are also meaningless since it's impossible
# to import more than a single backend.
{.warning[UnreachableCode]: off.} 

proc init*(): bool =
  ## Initializes a database using values from the config file
  when dbEngine == "sqlite":
    return sqlite.init()
  when dbEngine == "postgres":
    return postgres.init()
  when dbEngine == "skeleton":
    return skeleton.init()
  when dbEngine == "mem":
    return mem.init()

proc addUser*(user: User): User =
  when dbEngine == "sqlite":
    return sqlite.addUser(user)
  when dbEngine == "postgres":
    return postgres.addUser(user)
  when dbEngine == "skeleton":
    return skeleton.addUser(user)
  when dbEngine == "mem":
    return mem.addUser(user)

proc userIdExists*(id:string): bool =
  ## A procedure to check if a user exists by id
  when dbEngine == "sqlite":
    return sqlite.userIdExists(id)
  when dbEngine == "postgres":
    return postgres.userIdExists(id)
  when dbEngine == "skeleton":
    return skeleton.userIdExists(id)
  when dbEngine == "mem":
    return mem.userIdExists(id)

proc userHandleExists*(handle:string): bool =
  ## A procedure to check if a user exists by handle
  when dbEngine == "sqlite":
    return sqlite.userHandleExists(handle)
  when dbEngine == "postgres":
    return postgres.userHandleExists(handle)
  when dbEngine == "skeleton":
    return skeleton.userHandleExists(handle)
  when dbEngine == "mem":
    return mem.userHandleExists(handle)

proc getUserById*(id: string): User =
  ## Retrieve a user from the database using their id
  when dbEngine == "sqlite":
    return sqlite.getUserById(id)
  when dbEngine == "postgres":
    return postgres.getUserById(id)
  when dbEngine == "skeleton":
    return skeleton.getUserById(id)
  when dbEngine == "mem":
    return mem.getUserById(id)

proc getUserByHandle*(handle: string): User =
  ## Retrieve a user from the database using their handle
  when dbEngine == "sqlite":
    return sqlite.getUserByHandle(handle)
  when dbEngine == "postgres":
    return postgres.getUserByHandle(handle)
  when dbEngine == "skeleton":
    return skeleton.getUserByHandle(handle)
  when dbEngine == "mem":
    return mem.getUserByHandle(handle)

proc updateUserByHandle*(handle, column, value: string): bool =
  ## A procedure to update the user by their handle
  when dbEngine == "sqlite":
    return sqlite.updateUserByHandle(handle,column,value)
  when dbEngine == "postgres":
    return postgres.updateUserByHandle(handle,column,value)
  when dbEngine == "skeleton":
    return skeleton.updateUserByHandle(handle,column,value)
  when dbEngine == "mem":
    return mem.updateUserByHandle(handle,column,value)

proc updateUserById*(id, column, value: string): bool = 
  ## A procedure to update the user by their ID
  when dbEngine == "sqlite":
    return sqlite.updateUserById(id,column,value)
  when dbEngine == "postgres":
    return postgres.updateUserById(id,column,value)
  when dbEngine == "skeleton":
    return skeleton.updateUserById(id,column,value)
  when dbEngine == "mem":
    return mem.updateUserById(id,column,value)

proc getIdFromHandle*(handle: string): string =
  ## A function to convert a user handle to an id.
  when dbEngine == "sqlite":
    return sqlite.getIdFromHandle(handle)
  when dbEngine == "postgres":
    return postgres.getIdFromHandle(handle)
  when dbEngine == "skeleton":
    return skeleton.getIdFromHandle(handle)
  when dbEngine == "mem":
    return mem.getIdFromHandle(handle)

proc getHandleFromId*(id: string): string =
  ## A function to convert a  id to a handle.
  when dbEngine == "sqlite":
    return sqlite.getHandleFromId(id)
  when dbEngine == "postgres":
    return postgres.getHandleFromId(id)
  when dbEngine == "skeleton":
    return skeleton.getHandleFromId(id)
  when dbEngine == "mem":
    return mem.getHandleFromId(id)

proc addPost*(post: Post): Post =
  ## A function add a post into the database
  when dbEngine == "sqlite":
    return sqlite.addPost(post)
  when dbEngine == "postgres":
    return postgres.addPost(post)
  when dbEngine == "skeleton":
    return skeleton.addPost(post)
  when dbEngine == "mem":
    return mem.addPost(post)

proc postIdExists*(id: string): bool =
  ## A function to see if a post id exists in the database
  when dbEngine == "sqlite":
    return sqlite.postIdExists(id)
  when dbEngine == "postgres":
    return postgres.postIdExists(id)
  when dbEngine == "skeleton":
    return skeleton.postIdExists(id)
  when dbEngine == "mem":
    return mem.postIdExists(id)

proc updatePostById*(id, column, value: string): bool =
  ## A procedure to update a post using it's id
  when dbEngine == "sqlite":
    return sqlite.updatePostById(id,column,value)
  when dbEngine == "postgres":
    return postgres.updatePostById(id,column,value)
  when dbEngine == "skeleton":
    return skeleton.updatePostById(id,column,value)
  when dbEngine == "mem":
    return mem.updatePostById(id,column,value)

proc getPostById*(id: string): Post =
  ## A procedure to get a post object from the db using its id
  when dbEngine == "sqlite":
    return sqlite.getPostById(id)
  when dbEngine == "postgres":
    return postgres.getPostById(id)
  when dbEngine == "skeleton":
    return skeleton.getPostById(id)
  when dbEngine == "mem":
    return mem.getPostById(id)

proc getPostsByUserHandle*(handle:string, limit: int = 15): seq[Post] =
  ## A procedure to get any user's posts from the db using the users handle
  when dbEngine == "sqlite":
    return sqlite.getPostsByUserHandle(handle,limit)
  when dbEngine == "postgres":
    return postgres.getPostsByUserHandle(handle,limit)
  when dbEngine == "skeleton":
    return skeleton.getPostsByUserHandle(handle,limit)
  when dbEngine == "mem":
    return mem.getPostsByUserHandle(handle,limit)

proc getPostsByUserId*(id:string, limit: int = 10): seq[Post] =
  ## A procedure to get any user's posts from the db using the users id
  when dbEngine == "sqlite":
    return sqlite.getPostsByUserId(id,limit)
  when dbEngine == "postgres":
    return postgres.getPostsByUserId(id,limit)
  when dbEngine == "skeleton":
    return skeleton.getPostsByUserId(id,limit)
  when dbEngine == "mem":
    return mem.getPostsByUserId(id,limit)

proc getAdmins*(limit: int = 5): seq[string] =
  ## A procedure that returns the usernames of all administrators.
  when dbEngine == "sqlite":
    return sqlite.getAdmins(limit)
  when dbEngine == "postgres":
    return postgres.getAdmins(limit)
  when dbEngine == "skeleton":
    return skeleton.getAdmins(limit)
  when dbEngine == "mem":
    return mem.getAdmins(limit)

proc getTotalUsers*(): int =
  ## A procedure to get the total number of local users.
  when dbEngine == "sqlite":
    return sqlite.getTotalUsers()
  when dbEngine == "postgres":
    return postgres.getTotalUsers()
  when dbEngine == "skeleton":
    return skeleton.getTotalUsers()
  when dbEngine == "mem":
    return mem.getTotalUsers()

proc getTotalPosts*(): int =
  ## A procedure to get the total number of local posts.
  when dbEngine == "sqlite":
    return sqlite.getTotalPosts()
  when dbEngine == "postgres":
    return postgres.getTotalPosts()
  when dbEngine == "skeleton":
    return skeleton.getTotalPosts()
  when dbEngine == "mem":
    return mem.getTotalPosts()
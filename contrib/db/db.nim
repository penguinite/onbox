# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.
#
# db.nim: 
## This module provides a compile-time wrapper for database operations
## Pothole needs to support multiple database engines such as sqlite, postgres and other exotic ones.
## This is a nice trade-off between complexity and choice, you can choose your preferred database engine
## when compilling and it also leads to smaller binary sizes since it's unlikely you will need to switch engines often.
## 
## 
## By default, libpothole uses sqlite in debugging and it uses postgres in production/release.
## But this can be configured by supplying -d:dbEngine=DATABASE_BACKEND to the nimble command.
## So to use sqlite, you would supply: -d:dbEngine=sqlite
## or postgres: -d:dbEngine=postgres
## 
## *Note: Make sure to supply the database backend **before** build task.*
## *Do it like this: nimble -d:dbEngine=DB_BACKEND build*
## *and not like this: nimble build -d:dbEngine=DB_BACKEND*

#! Note to my future employer: Please don't look at this code.
# I really wanted to add support for multiple databases,
# and a choice like that doesn't come with its own consequences.
# I had to sacrifice code readability for this.

from user import User
from post import Post

{.experimental: "codeReordering".}

when defined(dbEngine):
  const dbEngine {.strdefine.}: string = ""
else:
  when defined(release):
    const dbEngine = "sqlite" # The postgres database backend is not very good.
  else:
    const dbEngine = "sqlite"

{.hint: "Using " & dbEngine & " as database engine.".}

# TODO: Look into using templates to improve code quality.

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

proc init*(noSchemaCheck:bool = false): bool =
  ## Initializes a database using values from the config file
  ## This should also handle database migration from the database schema of the previous release.
  ## You can supply a filename, this is obviously only relevant for sqlite.
  when dbEngine == "sqlite":
    return sqlite.init(filename, noSchemaCheck)
  when dbEngine == "postgres":
    return postgres.init(noSchemaCheck)
  when dbEngine == "skeleton":
    return skeleton.init(noSchemaCheck)
  when dbEngine == "mem":
    return mem.init(noSchemaCheck)

proc uninit*(): bool =
  ## Closes the active database connection. 
  ## You will of course have to run this when exiting due to errors or something else.
  when dbEngine == "sqlite":
    return sqlite.uninit()
  when dbEngine == "postgres":
    return postgres.uninit()
  when dbEngine == "skeleton":
    return skeleton.uninit()
  when dbEngine == "mem":
    return mem.uninit()

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
  ## Checks if a user exists using their handle.
  # This code relies on an external database file. Which we obviously cannot provide.
  # So to get it to build, we need to supply this.
  runnableExamples "-r:off":
    discard db.init()
    if not db.userHandleExists("john"):
      echo "No account with the handle john."
    else:
      echo "Welcome back john!"
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
# Copyright © Leo Gavilieau 2022-2023
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
## This module only provides a couple of compile-time code to switch between
## Postgres and sqlite. The functions between those two modules are mostly the same
## so you do not have to worry about it for the most part.
## 
## Though, you should check the dbEngine constant. You can simply import this
## module and use check what database engine dbEngine is pointing to at compile
## time
## 
## Do not write code under the assumption that only one database engine will be
## used unless you have configured all your build systems to explicitly use only
## one database.


when defined(dbEngine):
  const dbEngine* {.strdefine.}: string = "" ## The dbEngine constant is used to signify what database engine the user wants at compile-time.
else:
  when defined(docs):
    const dbEngine* = "docs"
  else:
    const dbEngine* = "sqlite"

when dbEngine == "postgres":
  import db/postgres
  export postgres

when dbEngine == "sqlite":
  import db/sqlite
  export sqlite

when dbEngine == "docs": # For documentation only.
  type
    User = ref object
    Post = ref object

  proc init*(noSchemaCheck:bool = true): bool =
    ## This procedure initializes a database. It checks for any inconsistencies and makes sure everything is ready for the main program.
    ## *Note: This module is defined differently in the postgres and sqlite modules, make sure to check the documentation in those modules too!*
    runnableExamples "--run:off":
      # For sqlite
      when dbEngine == "sqlite":
        var database_file = "__eat_flaming_death.db"
        discard db.init(database_file) # Optionally add true at the end to skip the schema check
      # For postgres
      when dbEngine == "postgres":
        var
          host = "__eat_flaming_death:5432"
          database_name = "pothole"
          database_user = "ph"
          password = "very_secure_password"
        discard db.init(host, database_name, database_user, password) # Optionally add true at the end to skip the schema check
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
  
  proc getLocalPosts*(limit: int = 15): seq[Post] =
    ## A procedure to get posts from local users only.
    ## Set limit to 0 to disable the limit and get all posts from local users.
    return @[Post()]
# Copyright © Leo Gavilieau 2022-2023
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


const dbEngine* {.strdefine.}: string = "sqlite" ## The dbEngine constant is used to signify what database engine the user wants at compile-time.

when dbEngine == "sqlite":
  import db/sqlite
  export sqlite

when dbEngine == "postgres":
  import db/postgres
  export postgres

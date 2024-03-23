# Copyright © penguinite 2024 <penguinite@tuta.io>
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
# db/sqlite/postrevisions.nim:
## This module contains all database logic for handling revisions of posts.

# From somewhere in the standard library
import std/tables


const postsRevisionsCols*: OrderedTable[string, string] = {"id": "TEXT PRIMARY KEY NOT NULL", # This contains the id of the revision, because of course we ought to have an id for everything.
  "published": "TIMESTAMP NOT NULL", # This contains the date of when the revision was made
  "content": "TEXT NOT NULL DEFAULT ''", # This contains past revisions
  "pid": "TEXT NOT NULL", # This contains the id the post that the revision belongs to
  # TODO: This __A/__B hack is really, well, hacky. Maybe replace it?
  "__A": "foreign key (pid) references posts(id)",
}.toOrderedTable()
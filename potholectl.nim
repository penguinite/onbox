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
# potholectl:
## Potholectl is a command-line tool that provides a nice and simple interface to many of Pothole's internals.
## It can be used to create new users, delete posts, add new MRF policies, setup database containers and more!
## Generally, this command aims to be a Pothole instance administrator's best friend.
import potholectl/[misc, smrf, sdb, suser]
import cligen

dispatchMultiGen(
  ["db"],
  [check, help= {"config": "Location to config file"}, mergeNames = @["potholectl", "db"]],
  [clean, help= {"config": "Location to config file"}, mergeNames = @["potholectl", "db"]],
  [purge, help= {"config": "Location to config file"}, mergeNames = @["potholectl", "db"]],
  [psql, help= {"config": "Location to config file"}, mergeNames = @["potholectl", "db"]],
  [docker,
    help= {
      "config": "Location to config file",
      "name": "Sets the name of the database container",
      "allow_weak_password": "Does not change password automatically if its weak",
      "expose_externally": "Exposes the database container (potentially to the outside world)",
      "ipv6": "Sets some IPv6-specific options in the container"
    }, mergeNames = @["potholectl", "db"]]
)

dispatchMultiGen(
  ["user"],
  [suser.new,
    help = {
    "admin": "Makes the user an administrator",
    "moderator": "Makes the user a moderator",
    "require-approval": "Turns user into an unapproved user",
    "display": "Specifies the display name for the user",
    "bio": "Specifies the bio for the user",
    "config": "Location to config file"
    }, mergeNames = @["potholectl", "user"]],
  [suser.delete,
    help = {
      "id": "Specifies whether or not the thing provided is an ID",
      "handle": "Specifies whether or not the thing provided is an handle",
      "purge": "Whether or not to delete all the user's posts and other data",
      "config": "Location to config file"
    }, mergeNames = @["potholectl", "user"]],
  [suser.info,
    help = {
      "quiet": "Makes the program a whole lot less noisy.",
      "id":"Print only user's ID",
      "handle":"Print only user's handle",
      "display":"Print only user's display name",
      "admin": "Print user's admin status",
      "moderator": "Print user's moderator status",
      "request": "Print user's approval request",
      "frozen": "Print user's frozen status",
      "email": "Print user's email",
      "bio":"Print user's biography",
      "password": "Print user's password (hashed)",
      "salt": "Print user's salt",
      "kind": "Print the user's type/kind",
      "config": "Location to config file"
    }, mergeNames = @["potholectl", "user"]],
  [suser.id,help = {"quiet": "Print only the ID and nothing else.","config": "Location to config file"}, mergeNames = @["potholectl", "user"]],
  [suser.handle,help = {"quiet": "Print only the handle and nothing else.","config": "Location to config file"}, mergeNames = @["potholectl", "user"]],
  [suser.hash,help = {"quiet": "Print only the hash and nothing else.","algo": "Allows you to specify the KDF algorithm to use."}, mergeNames = @["potholectl", "user"]],
)

dispatchMultiGen(
  ["mrf"],
  [view, help={"filenames": "List of modules to inspect"}, mergeNames = @["potholectl", "mrf"]],
  [compile, help={"filenames": "List of files to compile"}, mergeNames = @["potholectl", "mrf"]]
)

dispatchMulti(
  [db, doc="Operations related to database maintenance, run db help or db -h for help.", stopWords = @["check", "clean", "docker"], suppress = @[ "usage", "prefix" ]],
  [mrf, doc="Operations related to custom MRF policies, run mrf help or mrf -h for help.", stopWords = @["view", "compile"], suppress = @[ "usage", "prefix" ]],
  [user, doc="Operations related to user and user management, run user help or user -h for help.", stopWords = @["new", "delete", "info", "id", "handle", "hash"], suppress = @[ "usage", "prefix" ]],
  [render, help={"filename": "Location to template file", "config": "Location to config file"}],
  [ids], [handles], [dates]
)
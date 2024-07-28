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
import potholectl/[misc, smrf, sdb, suser, spost]
import cligen

dispatchMulti(
  [user_new,
    help = {
    "admin": "Makes the user an administrator",
    "moderator": "Makes the user a moderator",
    "require-approval": "Turns user into an unapproved user",
    "display": "Specifies the display name for the user",
    "bio": "Specifies the bio for the user",
    "config": "Location to config file"
    }],

  [user_delete,
    help = {
      "id": "Specifies whether or not the thing provided is an ID",
      "handle": "Specifies whether or not the thing provided is an handle",
      "purge": "Whether or not to delete all the user's posts and other data",
      "config": "Location to config file"
    }],

  [user_info,
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
    }],

  [user_id,
    help = {
      "quiet": "Print only the ID and nothing else.",
      "config": "Location to config file"
    }],

  [user_handle,
    help = {
      "quiet": "Print only the handle and nothing else.",
      "config": "Location to config file"
    }],

  [post_new, cmdName = "new",
    help = {
      "mentioned": "A comma-separated list of users who are mentioned in this post.",
      "replyto": "Specifies what post we are replying to by its ID.",
      "date": "Specifies the post's creation date (see potholectl date for the format)",
      "config": "Location to config file",
    }],

  [db_check, help= {"config": "Location to config file"}],
  [db_clean, help= {"config": "Location to config file"}],
  [db_purge, help= {"config": "Location to config file"}],
  [db_psql, help= {"config": "Location to config file"}],
  [db_docker,
    help= {
      "config": "Location to config file",
      "name": "Sets the name of the database container",
      "allow_weak_password": "Does not change password automatically if its weak",
      "expose_externally": "Exposes the database container (potentially to the outside world)",
      "ipv6": "Sets some IPv6-specific options in the container"
    }],

  [mrf_view, help={"filenames": "List of modules to inspect"}],
  [mrf_compile, help={"filenames": "List of files to compile"}],

  [hash,
    help = {
      "quiet": "Print only the hash and nothing else.",
      "algo": "Allows you to specify the KDF algorithm to use."
    }],
  [render, help={"filename": "Location to template file", "config": "Location to config file"}],
  [ids], [handles], [dates]
)
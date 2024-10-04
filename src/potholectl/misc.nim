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
# ctl/template.nim:
## Operations related to templating.

# From somewhere in Pothole
import pothole/[conf, database]
from pothole/routeutils import prepareTable
import std/strutils

# From third-party programs
import temple

proc render*(filename: seq[string], config = "pothole.conf"): int =
  ## This command allows you to render a template file the same way that Pothole does.
  ## 
  ## When you give this command a filename, Pothole will open it, render it and print out the output 
  ## 
  if len(filename) == 0 or filename.join(" ").isEmptyOrWhitespace():
    echo "Invalid usage, try running with -h for help."
    quit(1)

  # Initialize config
  var cnf = conf.setup(config)

  # Initialize database
  var db = setup(
    cnf.getDbName(),
    cnf.getDbUser(),
    cnf.getDbHost(),
    cnf.getDbPass()
  )

  var input = ""
  try:
    input = readFile(filename.join(" "))
  except CatchableError as err:
    echo err.msg
    return 1

  echo templateify(input, prepareTable(cnf, db))
  return 0

# Some extra educational content for system administrator

proc ids*(): int =
  ## Educational material about IDs
  echo  """
Pothole abstract nearly every single thing into some object with an "id"
Users have IDs and posts have IDs.
So do activities, media attachments, reactions, boosts and so on.

Internally, pothole translates any human-readable data (such as a handle, see `potholectl handles`)
into an id that it can use for manipulation, data retrieval and so on.

This slightly complicates everything but potholectl will try to make an educated guess.
If you do know whether something is an ID or not, then you can use the -i flag to tell potholectl not to double check.
Of course, this differs with every command but it should be possible."""
  return 0

proc handles*(): int =
  ## Educational material about handles
  echo """
A handle is basically what pothole calls the "username"
A handle can be as simple as "john" or "john@example.com"
A handle is not the same thing as an email address.
In pothole, the handle is used as a login name and also as a user finding mechanism (for federation)"""
  return 0

proc dates*(): int =
  ## Educational material about date handling in Pothole.
  echo """
This is not exactly a subsystem but a help entry for people confused by dates in potholectl.
Dates in potholectl are formatted like so: yyyy-MM-dd HH:mm:ss
This means the following:
  1. 4 numbers for the year, and then a hyphen/dash (-)
  2. 2 numbers for the month, and then a hyphen/dash (-)
  3. 2 numbers for the day, and then a hyphen/dash (-)
  4. A space
  5. 2 numbers for the hour and then a colon (:)
  6. 2 numbers for the minute and then a colon (:)
  7. 2 numbers for the second

Here are examples of dates in this format:
UNIX Epoch starting date: "1970-01-01 00:00:00"
Year 2000 problem date: "1999-12-31 23:59:59"
Year 2038 problem date: "2038-01-19 03:14:07"
Year 2106 problem date: "2106-02-07 06:28:15"
The date this was written: "2024-03-23 13:09:26"

Make sure to wrap the date around with double quotes, that way there won't be any mistakes!"""
  return 0
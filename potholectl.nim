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
import potholectl/[misc, mrf, dev, db]
import std/macros

when isMainModule:
  import cligen
  dispatchMulti(
    [db, doc="Operations related to database maintenance, run db help or db -h for help.", stopWords = @["check", "clean", "docker"], suppress = @[ "usage", "prefix" ]],
    [mrf, doc="Operations related to custom MRF policies, run mrf help or mrf -h for help.", stopWords = @["view", "compile"], suppress = @[ "usage", "prefix" ]],
    [dev, doc="Helpful commands for Pothole developers, run dev help or dev -h for help.", stopWords = @["db", "clean", "psql"], suppress = @[ "usage", "prefix" ]],
    [render, help={"filename": "Location to template file", "config": "Location to config file"}],
    [ids], [handles], [dates]
  )
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
# api.nim:
## This module just serves as a wrapper for all the modules in the api folder

# From somewhere in Pothole
import pothole/api/[instance, ph, apps]
export instance, ph, apps

# From somewhere in the standard library
import std/[tables]

const apiRoutes* =  {
  # URLRoute : (HttpMethod, RouteProcedure)
  # /api/ is already inserted before every URLRoute
  "v1/instance": ("GET", v1InstanceView),
  "v2/instance": ("GET", v2InstanceView),
  "v1/instance/rules": ("GET", v1InstanceRules),
  "v1/instance/extended_description": ("GET", v1InstanceExtendedDescription),
  "v1/apps": ("POST", v1Apps),
  "ph/v1/about": ("GET", phAbout)
}.toTable
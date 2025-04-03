# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
#
# This file is part of Onbox.
# 
# Onbox is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Onbox is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Onbox. If not, see <https://www.gnu.org/licenses/>. 
#
# db/private/utils.nim:
## This module contains common procedures & macros used by the database layer
## in Onbox.
import std/macros

macro get*(obj: object, fld: string): untyped =
  ## A procedure to get a field of an object using a string.
  ## Like so: user.get("local") == user.local
  newDotExpr(obj, newIdentNode(fld.strVal))
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
# libpothole.nim:
## This module is primarily used for documentation building via this cmd:
## nim doc --project libpothole.nim
## or the `docs` target in the Makefile.

{.warning: "This module leads to severe breakage! Do not use at all!".}

# These warnings would overwhelm the build output.
# And they are also meaningless since it's impossible
# since this module is not intended to be used.
{.warning[UnreachableCode]: off.} 
{.warning[UnusedImport]: off.}

#import pothole/db/[sqlite, mem, postgres] # Not needed for documentation.
import pothole/[conf,crypto,db,debug,lib,post,potcode,user]
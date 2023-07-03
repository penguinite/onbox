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
# activity.nim
## This provides the type definition for "Activity" objects.
## An Activity is basically something like a Like, Boost or Reply.
## This module provides functions for dealing with said "Activities"
## such as transforming them into sequences that can be fed into other procedures.
## Our object is very similar to ActivityPub's Activities, this is by design.
## And including them in a separate activity.nim module is also by design.
from post import Post 
from user import User

type

  ActivityKind* = enum ## All different Activity Types https://www.w3.org/TR/activitystreams-vocabulary/#h-activity-types
    Accept, Add, Announce, Arrive, Block, Create, Delete, Dislike, Flag,
    Follow, Ignore, Invite, Join, Leave, Like, Listen, Move, Offer, Question,
    Reject, Read, Remove, TentativeReject, TentativeAccept, Travel, Undo,
    Update, View

  Activity* = object
    kind*: ActivityKind
    user*: User
    obj*: Post
    target*: Post

#[
  
  Accept, Reject, Invite 

]#
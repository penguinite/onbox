# Copyright © Leo Gavilieau 2023 <xmoo@privacyrequired.com>
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
# debug.nim:
## Common procedures for debugging. Right now this is used to create
## fake users and fake posts. You will not need this, and you should 
## not depend on this in your app at all!

import user, post, crypto

const fakeNames = @["Jeremy", "Jane Doe", "pyro", "Tavish Finnegan DeGroo", "Mikhail", "Dell Conagher", "Ludwig Humboldt", "Mundy", "spy"]
const fakeHandles = @["scout","soldier","pyro","demoman","heavy","engineer", "medic", "sniper", "spy"]
const fakeBios = @["All the ladies love me!", "GOD BLESS AMERICA", "Apparently, this user prefers to keep an air of mystery about them.", "God bless Scotland!", "Craving sandvich.", "I solve practical problems and I have 11 PhDs.", "Professional doctor who previously had a medical license.", "Me", "Scout is a virgin"]

proc getFakeUsers*(): seq[User] =
  # Creates 10 fake users
  result = @[]
  for x in 0 .. len(fakeHandles) - 1:
    var user = newUser(fakeHandles[x], randomString(), true)
    user.name = fakeNames[x]
    user.bio = fakeBios[x]
    result.add(user)
  return result

const fakeStatuses = @["Hello World!", "To be weak is to be strong but unconventional", "I like to keep an air of mystery around me", "Here's a cute picture of a cat! (I don't know how to use this app, I am sorry if the picture does not appear)", "Cannabis abyss and Pot hole mean the same thing.", "Woke up, had some coffee, ran over a child during my commute to work, escaped masterfully.\n\nHow was your day?","\"It's GNU/Linux\"\n\"It's just Linux\"\n\nThey don't know that it's...\nwhatever the fuck you want to call it\nlife is meaningless, we're all gonna die","The FBI looking at me googling \"How to destroy children\": 😨\nThe FBI looking at me after clarifying im programming in C: 😇","When god falls, I will find the spigot upon which they meter out grace and smash it permanently open.","No matter how much I ferventley pray, god never reveals why they deeply dislike me.","Always store confidential data in /dev/urandom for safety!\nNo one can recover data from /dev/urandom","If you want a job, write software.\nIf you want a career, write a package manager.","Lorem Ipsum Dolor Sit Amet","It does not matter how slow you go as long as you do not stop.","Sometimes the most impressive things are the simplest things","systemd introduces new tool called systemd-lifed\n\nsimply create a config file and systemd will possess your body and take cake of your own life for you.","Hello from libpothole!"]

proc getFakePosts*(): seq[Post] =
  # Creates 10 fake Posts.
  result = @[]
  for x in fakeStatuses:
    var post = newPost(fakeHandles[rand(len(fakeHandles) - 1)], "", x, @[], true)
    result.add(post)
  return result

proc showFakePosts*() =
  for x in fakeStatuses:
    var post = newPost(fakeHandles[rand(len(fakeHandles) - 1)], "", x, @[], true)
    echo "---"
    echo("Author: " & post.sender)
    echo(post.content)

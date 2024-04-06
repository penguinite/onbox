# Copyright © Leo Gavilieau 2023 <xmoo@privacyrequired.com>
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
# debug.nim:
## Common procedures for debugging. This is only useful for creating
## fake users and fake posts (for testing)
import std/[tables]
import potholepkg/[user, post, crypto, lib, database, conf]

const fakeNames = @["Jeremy", "Jane Doe", "pyro", "Tavish Finnegan DeGroo", "Mikhail", "Dell Conagher", "Ludwig Humboldt", "Mundy", "spy"]
const fakeHandles* = @["scout","soldier","pyro","demoman","heavy","engineer", "medic", "sniper", "spy"]
const fakeBios = @["All the ladies love me!", "GOD BLESS AMERICA", "Apparently, this user prefers to keep an air of mystery about them.", "God bless Scotland!", "Craving sandvich.", "I solve practical problems and I have 11 PhDs.", "Professional doctor who previously had a medical license.", "Me", "Scout is a virgin"]

proc getFakeUsers*(): seq[User] =
  # Creates 10 fake users
  var sequence: seq[User];

  for x in 0 .. high(fakeHandles):
    var user = newUser(fakeHandles[x], true, "")
    if rand(5) == 1: user.admin = true
    user.name = fakeNames[x]
    user.id = fakeHandles[x] # Reset ID for easier testing.
    user.kdf = lib.kdf
    user.bio = fakeBios[x]
    sequence.add(user)

  return sequence

const fakeStatuses* = @[
  "Hello World!", 
  "I hate writing database stuff...", 
  "I like to keep an air of mystery around me", 
  "Here's a cute picture of a cat! (I don't know how to use this app, I am sorry if the picture does not appear)", 
  "Cannabis abyss and Pot hole mean the same thing.", 
  "Woke up, had some coffee, hit a car during my commute to work, escaped masterfully.\n\nHow was your day?",
  "\"It's GNU/Linux\"\n\"It's just Linux\"\n\nThey don't know that it's...\nwhatever the fuck you want to call it\nlife is meaningless, we're all gonna die",
  "The FBI looking at me googling \"How to destroy children\": 😨\nThe FBI looking at me after clarifying im programming in C: 😇",
  "When god falls, I will find the spigot upon which they meter out grace and smash it permanently open.",
  "No matter how much I ferventley pray, god never reveals why they deeply dislike me.",
  "Always store confidential data in /dev/urandom for safety!\nNo one can recover data from /dev/urandom",
  "If you want a job, write software.\nIf you want a career, write a package manager.",
  "Lorem Ipsum Dolor Sit Amet",
  "It does not matter how slow you go as long as you do not stop.",
  "Sometimes the most impressive things are the simplest things",
  "systemd introduces new tool called systemd-lifed\n\nsimply create a config file and systemd will possess your body and take cake of your own life for you.",
  "Hello from potholepkg!",
  "Consider: inhaling spaghetti",
  "Man. I love AI lawyers so much.\n\"Mr. Doe, how do you justify these grave crimes?\"\n\"Uh... Connection timed out?\"\n",
  "It is hell here!",
  "Anna is eating a canary",
  "He says he is a model but really he is a priest",
  "I don't love you, I only love mayonnaise.",
  "He informed the jury that he was too pretty to go to jail.",
  "THERE IS A PROBLEM! He uh... wants to come with his cow.",
  "Jeg er osten",
  "I thought it was an apple store but they only sold computers.",
  "What does 8008 look like on a calculator?",
  "I am going out for a walk with my lawyer",
  "Excuse me! I have become an apple!",
  "DE KOMMER IND LIGE NU! IGENNEM VINDUERNE!",
  "Hello World! -- penguinite!",
  """
<Guo_Si> Hey, you know what sucks?
<TheXPhial> vaccuums
<Guo_Si> Hey, you know what sucks in a metaphorical sense?
<TheXPhial> black holes
<Guo_Si> Hey, you know what just isn't cool?
<TheXPhial> lava?
  """,
  """
<tatclass> YOU ALL SUCK DICK
<tatclass> er.
<tatclass> hi.
<andy\code> A common typo.
<tatclass> the keys are like right next to each other.
  """,
  """
<Khassaki> HI EVERYBODY!!!!!!!!!!
<Judge-Mental> try pressing the the Caps Lock key
<Khassaki> O THANKS!!! ITS SO MUCH EASIER TO WRITE NOW!!!!!!!
<Judge-Mental> fuck me
  """,
  "I gotta go.  There's a dude next to me and he's watching me type, which is sort of starting to creep me out.  Yes dude next to me, I mean you.",
  "I hated going to weddings. All the grandmas would poke me saying \"You're next\". They stopped that when I started doing it to them at funerals.",
  """
<reo4k> just type /quit whoever, and it'll quit them from irc
* luckyb1tch has quit IRC (r`heaven)
* r3devl has quit IRC (r`heaven)
* sasopi has quit IRC (r`heaven)
* phhhfft has quit IRC (r`heaven)
* blackersnake has quit IRC (r`heaven)
<ibaN`reo4k[ex]> that's gotta hurt
<r`heaven> :(
  """,
  "* Porter is now known as PorterWITHGIRLFRIENDWHOISHOT\n<Strayed> he shot his girlfriend?",
  "Mike3285: wtf is a palindrome\nMaroonSand: no its not dude",
  "I'm my own worst enemy but the enemy of my enemy is my friend so I'm also my own best friend it's just basic math"
]


const reactions* = @[
  # Some sample reactions.
  "happy","sad","angry","disgusted","favorite"
]

const boosts* = @[
  # Some sample boost levels.
  "all","followers","local","private"
]

proc getFakePosts*(): seq[Post] =
  # Creates 10 fake Posts.
  result = @[]

  for x in fakeStatuses:
    var post = newPost(
      sender = fakeHandles[rand(high(fakeHandles))],  # Set random sender
      content = x, # Set content
      recipients = @[], # Set 0 recipients
      local = true # Set local
    )
    result.add(post)
  return result

proc getFakeReactions*(): Table[string, seq[string]] = 
  var users: seq[string] = @[]
  for i in 0..rand(5):
    for i in 0..rand(high(fakeHandles)):
      users.add(fakeHandles[i])
    result[reactions[rand(high(reactions))]] =  users
  return result

proc getFakeBoosts*(): Table[string, seq[string]] =
  var users: seq[string] = @[]
  for i in 0..rand(5):
    for i in 0..rand(high(fakeHandles)):
      users.add(fakeHandles[i])
    result[boosts[rand(high(boosts))]] = users
  return result

proc showFakePosts*() =
  for x in fakeStatuses:
    var post = newPost(fakeHandles[rand(high(fakeHandles))], "", x, @[], true)
    echo "---"
    echo("Author: " & post.sender)
    echo(post.content)

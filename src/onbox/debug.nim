# Copyright © Leo Gavilieau 2023 <xmoo@privacyrequired.com>
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
# debug.nim:
## Procedures used in the test-suite (includes fake data)
import db/[users, posts], shared
import rng, std/times

const userData* = @[
  ("scout", "Jeremy", "All the ladies love me!"),
  ("soldier", "Jane Doe", "GOD BLESS AMERICA"),
  ("pyro", "pyro", "Apparently, this user prefers to keep an air of mystery about them."),
  ("demoman", "Tavish Finnegan DeGroo", "God bless Scotland!"),
  ("heavy", "Mikhail", "Craving sandvich."),
  ("engineer", "Dell Conagher", "I solve practical problems and I have 11 PhDs."),
  ("medic", "Ludwig Humboldt", "Professional doctor who previously had a medical license."),
  ("sniper", "Mundy", "A professional with standards. NOT A MURDERER"),
  ("spy", "spy", "Scout is a virgin")
]

const fakeStatuses* = @[
  "Rhythm Heaven Fever OST goes so damn hard!!!",
  "Hello World!",
  "I hate writing database stuff...",
  "All's well until the debian developers decide that a song lyric in a test suite is in violation of copyright",
  "I like to keep an air of mystery around me", 
  "Here's a cute picture of a cat! (I don't know how to use this app, I am sorry if the picture does not appear)", 
  "Cannabis abyss and Pot hole mean the same thing.", 
  "Connected container and On box mean the same thing.",
  "Woke up, had some coffee, hit a car during my commute to work, escaped masterfully.\n\nHow was your day?",
  "\"It's GNU/Linux\"\n\"It's just Linux\"\n\nThey don't know that it's...\nwhatever the fuck you want to call it\nlife is meaningless, we're all gonna die",
  "The FBI looking at me googling \"How to kill child\": 😨\nThe FBI looking at me after I clarify I meant a child process: 😇",
  "Someone will step in, wielding a bat. And the spigot upon which grace drips will be smashed open permanently encasing the world in enlightenment.",
  "Always store confidential data in /dev/urandom for safety!\nNo one can recover data from /dev/urandom",
  "Fucking hate monkey watch man... I HATE MAINTAINING POLYRHYTHM SO MUCH!",
  "If you want a job, write software.\nIf you want a career, write a package manager.\nIf you want an obsession, work at FSF.",
  "Lorem Ipsum Dolor Sit Amet",
  "Ook-ook! (How was this post?) Ook-ook! (Did you like it?)",
  "[INSERT AN EINSTEIN QUOTE HERE]",
  "It does not matter how slow you go as long as you do not stop.",
  "Sometimes the most impressive things are the simplest things",
  "systemd introduces new tool called systemd-lifed\n\nsimply create a config file and systemd will possess your body and take cake of your own life for you.",
  "Hello from potholepkg!",
  "Consider: inhaling spaghetti",
  "Man. I love AI lawyers so much.\n\"Mr. Doe, how do you justify these grave crimes?\"\n\"Uh... Connection timed out?\"\n",
  "It is hell here!",
  "That teal-haired girl over there... did you know she owns this world? it's all hers.",
  "boku wa umare soshite kidzuku shosen hito no manegato shite nao mo utai tsudzuku towa no inochi \"VOCALOID\"",
  "Anna is eating a canary",
  "He says he is a model but really he is a priest",
  "proseka players looking at SEGA after they select him as the winner of 547th ULTIMATE contest...",
  "I don't love you, I only love mayonnaise.",
  "He informed the jury that he was too pretty to go to jail.",
  "THERE IS A PROBLEM! He uh... wants to come with his cow.",
  "Jeg er osten",
  "I thought it was an apple store but they only sold computers.",
  "What does 8008 look like on a calculator?",
  "I am going out for a walk with my lawyer",
  "Excuse me! I have become an apple!",
  "Board meeting goes so hard... and it ONLY lasts a minute!",
  "TO DO is the software engineering world's equivalent of \"I'll do it later\"\n\nThere is no later... There is never a later...",
  "DE KOMMER IND LIGE NU! IGENNEM VINDUERNE!",
  "I love it when test data incorporates sentimental or historical worth.",
  "Hello World! -- penguinite!",
  "As a reward, I will now speak in English!",
  "Play gekishou on master... do it! No balls!",
  "Hello from quark!",
  "Goodbye to quark... Maybe someday it'll be a good idea again",
  "Goodbye Pothole, Hello Onbox!",
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
* luckyb1tch has quit IRC (heaven)
* r3devl has quit IRC (heaven)
* sasopi has quit IRC (heaven)
* phhhfft has quit IRC (heaven)
* blackersnake has quit IRC (heaven)
<ibaN`reo4k[ex]> that's gotta hurt
<heaven> :(
  """,
  "* Porter is now known as PorterWITHGIRLFRIENDWHOISHOT\n<Strayed> he shot his girlfriend?",
  "Mike3285: wtf is a palindrome\nMaroonSand: no its not dude",
  "I'm my own worst enemy but the enemy of my enemy is my friend so I'm also my own best friend it's just basic math",
  "I am sentient, I am alive..."
]

proc genFakePosts*(): seq[Post] =
  ## Creates a couple of fake posts.
  for txt in fakeStatuses:
    var post = newPost()
    post.sender = sample(userData)[0]
    post.content = @[
      PostContent(
        kind: Text,
        txt_published: now().utc,
        txt_format: 0, # Plain
        text: txt
      )
    ]
    result.add(post)

proc genFakeUsers*(): seq[User] =
  ## Generates a couple of fake users
  for userData in userData:
    var user = newUser(userData[0], true)
    user.id = userData[0]
    user.name = userData[1]
    user.bio = userData[2]
    user.roles = @[-1]
    user.password = "DISABLED_FOREVER"
    result.add(user)
## Creates fake users and fake posts for debugging.
## You will not need this
## Note: These posts do not get federated to other instances.
## As this only uses db.addPost(), without running the actual call
## That sends the post to other servers.

import lib, user, post, crypto

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

const fakeStatuses = @["Hello World!", "To be weak is to be strong but unconventional", "I like to keep an air of mystery around me", "Here's a cute picture of a cat! (I don't know how to use this app, I am sorry if the picture does not appear)", "Cannabis abyss and Pot hole mean the same thing.", "Woke up, had some coffee, ran over a child during my commute to work, escaped masterfully.\n\nHow was your day?","\"It's GNU/Linux\"\n\"It's just Linux\"\n\nThey don't know that it's...\nwhatever the fuck you want to call it\nlife is meaningless, we're all gonna die","The FBI looking at me googling \"How to destroy children\": 😨\nThe FBI looking at me after clarifying im programming in C: 😇"]

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

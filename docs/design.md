---
title: "Design choices and development journal"
---

This is my personal development journal of Pothole.
I describe the choices I take here so that in the future
I or other people will understand why they were added, how they work and when they were added.

But I also document future ideas and other nifty things here.

I wanna try to make Pothole as light as possible. This means:

1.  Reducing dependencies whenever possible.
2.  Emphasizing readability over efficiency\*
3.  \*: Readable code is often the most efficient code.

So here are the things I decided.

## Using Nim as a programming language.

The arguments in the FAQ entry apply here too.

But, in addition to being fast, readable and just plain awesome.
The standard library includes a lot of modules,
you can do nearly anything you want!
Complex problems require dependencies but that's just fine.

Overall, the language is fun, safe and just plain awesome!

*Sidenote:* if you think that Nim is unsuitable for web apps
then I'd like you to take a look at Nitter which is written entirely in Nim.

## Considerations for this project

I have to go soon but I wanted to write a bit about what I want this
project to be, so that I do not lose track of myself.

First and foremost, I want pothole to be a lightweight microblogging
server. I want to get as close to minimalism and speed as I can and then
I want to turn Pothole into a customization heaven, what do I mean by
that? Well I am talking about something like Tumblr, where each user can
design their own \"blog\" with real HTML and CSS, that sounds exciting
to me!

**Note:** As of April 30th 2023, the feature to customize blogs with HTML (and Potcode) has been deprecated.
Instead, we will just let users customize the CSS.

Now, Tumblr has announced they will add ActivityPub support,
but most instances in the fediverse will probably block them considering how huge they are
(Tumblr has millions of users, an impossible amount to moderate effectively)
so I wanted to re-create one of the essential features of Tumblr,
custom user profiles, but in a much more deployable form and way lighter form.

If this succeeds, then we will have a:

1.  easy-to-deploy, lightweight and scalable microblogging server
2.  with support for multiple users
3.  where each user can design their own blog however they see fit.
4.  along with federation via ActivityPub

WHAT MORE COULD ANYONE POSSIBLY WANT! But that's in the future.
First, I have to work to achieve the first stage which is a stable, reliable ActivityPub backend that consumes little resources.


## Using a custom config language

Pothole uses a custom config language with a custom parser written by yours truly.
It's basically just `std/parsecfg`'s language but with support for multi-line arrays.

### Parse keys/options as lowercase by default.

I don't think it makes sense to distinguish "PORT", "Port" and "port" in the configuration file,
the configuration parser should ideally lowercase all values when adding them to `configTable`
so that programs don't worry about if they are spelling it right.

## Startup routine

When you run Pothole, it will search for a config file to parse.
The first thing it looks for is the `POTHOLE_CONFIG` environment variable
which should specify a location to the config file that Pothole is supposed to run.

It falls back to searching for a file named `pothole.conf` in the current working directory.

At the end of the entire startup routine it should start a webserver at 3500 or a port specified in the config file,
this means Pothole won't need root permissions but it also has to be proxied behind a much more powerful and stable web server (Nginx, Caddy etc.)

This approach is more secure rather than serving pages directly.

If we were to serve pages directly behind Prologue or Jester then
a security vulnerability in those programs (which probably is a common scenario)
could hijack a Pothole instance.

One could also argue that a security vulnerability in Nginx, Caddy or Apache would lead to a hijacked server.
That is true, but you could probably push out a security update quickly, since those projects are more popular than Prologue or Jester.

## Databases and data storage.

This section is all about the database, ie. what tables exist, their purpose and how they can be migrated.

I am not trying to add ActivityPub support *yet* but I am trying to experiment with a small-scale social networking app.

For now, I will be experimenting with sqlite databases,
it's important to note that sqlite is quite different.

### Postgres only.

Before November 2023, Pothole supported two databases (sqlite and postgres) but now I think this might be a bad idea.
I have always promised that maybe someday there will be a postgres backend in the future, all the while, I keep on optimizing the 
development engine (sqlite)

If I want pothole to be stable in 2024, I will have to nuke the sqlite engine and *only* work on postgres.
I would no longer have to test two different engines, only one and everything would be simpler when it comes
to the structure of the codebase.

Users no longer have to worry about which database engine their binary is compiled for. And the whole setup process becomes way simpler
I plan eventually on making friendly setup instructions for Pothole, if we kept on with this flawed idea then we would have to write 2 pages per distro.
Package maintainers working with binary-only or hybrid software such as `apt`, `guix`, `dnf`, `pacman` and so on would have to provide 2 packages

So, from now on, pothole only supports postgres irregardless of the `dbEngine` compile-time option.

### Database migrations

Pothole is versioned, so it would be easy to just say to include a database migration function in potholectl for every new version.

The potholectl commands `db migrate` and `db schema_check` do just that,
They allow you to migrate, if even neccessary and they allow you to check the schema of the current database.

So if you are an instance administrator who wants to upgrade,
all you have to do is run these commands, probably:

```sh
potholectl db schema_check
potholectl db migrate # Depending on the output of the previous command, we might skip this.
```

Though, I will add that Pothole's current database schema check is not perfect.
It only checks if the names of the User and Post tables match that of the hard-coded ones.
We should do more, such as checking if the tables have the same data types. But that's for later.

## ActivityPub

### To parse the context, or to not parse the context.

The "context" is a very weird parameter in JSON-LD,
it's basically like a XHTML namespace,
it contains definitions for various terms.
It's purpose is to help developers convert plain old JSON into something can be reliably reproduced and something way easier to store.

The question here is: Do we parse the context?

I will give you two examples in favor of parsing the @context:

1.  We can store activity data more efficiently.
Pleroma & Akkoma simply store the JSON in the database as-is, which is stupid because it takes a huge amount of space and you will have to parse it everytime you read it back.

2.  We maybe could detect false requests easier that way?
We could detect software pretending to be ActivityPub compliant and software that actually is ActivityPub-compliant and deal with them separately. 
Note: this might increase the time needed to successfully process Activities by a lot.

Modern and old computers are definitely fast enough to parse the ActivityStreams JSON-LD definitions every time there's the need to store Activity data
and we could also cache it or cache the result of it just to be sure.
But I am still confused as to how we can transform JSON into an effective format for database storage
or even how to use `@context` efficiently in the first-place! It's a mess!

What helped me understand `@context` a bit more is this quite from:

> context says "when i say actor i mean an ActivityStreams actor and not anything else like a movie actor".
> it defines type, structure, shape of data. And you can ensure that what you have is what you expect, instead of just assuming.
> -- <cite>[@a@pl.nulled.red](https://pl.nulled.red/users/a)</cite>

I want Pothole to be a reliable, efficient server and I think for it to be *that* reliable efficient server,
I am gonna have to do *something* with the `@context` even if its just validating the activity or storing the activity in a special storage-effective format.

Speaking of which, I decided to follow a third path which is to not use the context but
simply assume it's there by default, and whenever we receive an Activity,
we simply parse it into an action on a new or existing `Post` object

For example, `Create` activities create new Post object and `Delete` activities delete existing ones.

### How Pothole handles ActivityPub

For now, and for the forseeable future, Pothole will only support ActivityPub.

When Pothole receives a Activity it does the following:

1.  Checks for validity (HTTP Signatures, Server check and so on)
2.  Turns it into a Post/User and adds it into the db
3.  Simply exposes it either via the API or ActivityPub

### Will Pothole add support for other protocols?

Short answer, maybe. It depends on the protocol.

~pjals did tell me once that it would be sick to turn Pothole into a ActivityPub+Matrix server,
and it's internal infrastructure is quite well-suited for that
but I would rather fork it into a separate program that has Matrix support
and include a way for them to share messages (Unix socket perhaps?)

Or we could create a `matrix.nim` module specifically for this purpose
and we could simply add extra routes in the web server that correspond to Matrix paths.

## Known evils in the codebase.

This section contains a list of all the hacky, bloated or inefficient parts of the codebase in the pothole server repository and the libpothole repository.

These range from and to the following:

1.  Minor inefficiencies: Some parts of the code can be optimized elsewhere to yield faster, better or readable code.
2.  Heavy inefficiencies: A lot of the code is either badly written or can be optimized.
3.  Major inefficienies: A majority of the code is badly written, unoptimized, incomplete or all of the above. It should be re-written ASAP.

I encourage you to report any inefficient code whatsoever
(Just not minor inefficient code, I don't want to wake up to 50+ emails)

This is not something unique to Pothole, lots of software projects suffer from *some* inefficient code since nothing is perfect. 
The Linux kernel is inefficient, the firefox browser is inefficient and Mastodon is also inefficient
(particularly as to how it stores some media such as avatars and banners)
but people still use those since that's just a price to pay when using **any** modern software.

I want to clarify, the purpose of this section isn't to shame volunteer developers for not writing pristine Enterprise-quality code
but it's to just be a bit more transparent about the bottlenecks in Pothole's code.
If we can remove as much inefficiency as we can then that's awesome but there's simply no reason to be scared of code.

TL;DR: This is not suckless. 
Pothole *is* designed to be as efficient as possible but inefficient code will always be there, no matter what,
we're simply proud of this inevitable outcome instead of hiding it away or never speaking of it.

Inefficiency comes in lots of forms, there is readable slow code and
there is also unreadable fast code. Life isn't a perfect set of benefits,
every decision comes with some pros and cons. The main inefficiency we're worried about is unreadable code,
Pothole is written in Nim and Nim is designed with the idea that readable code is almost always the most efficient code.

We're only secondarily worried about slow code, but since we are using such an awesome language,we do not have to worry about this for the most part.
Memory safety and security is/will be discussed in a different section, since that's a completely different thing.
(We prioritize security over readablitity, duh.)

*Note:* Potholectl is allowed to be a bit slow or inefficient compared to the server program
since it is going to be primarily used for administrative tasks such as migrating databases, creating new users or removing old Activities.
I am not saying those actions deserve to be a bit slower, but we just have a slightly larger margin of inefficiency when it comes to Potholectl.

### Minor inefficiency

An example of a minor inefficiency is this:

```nim
var port: int = 3500;
web.serve(port)
```

In the above code we declare a variable that really does not need to be declared.
In most cases, minor inefficiencies often get overwritten by better code.

Minor inefficiencies are all over the codebase if one looks for them.
But it does not matter a whole lot so let's move on to the more important parts. 

### Heavy inefficiency

An example of Heavy inefficiency is the `load()` function in `potholepkg/conf.nim` at commit `8a294235aad9e9e72144c50ab918fb51327aa5bd`

The parser code is simply a mess, it works but it's just unreadable
and it's a pain to look at. You can easily take a look at it and tell that it needs to be re-written.

### Major inefficiency

Major inefficiencies are not everywhere in the codebase thankfully.
But it's still important to look out for them,
since they can present a significant bottleneck in performance


Common *past* examples of Major inefficiency include:

1. `potholepkg/database.nim` and `potholepkg/db/*`: This was before I found out about import and export statements. Which now make the codebase 10x cleaner.
2. `src/potcode.nim`: The easy solution to this was to simply nuke the Potcode feature.

## Caching webpages.

We could create a sort of cache table to speed up requests.

It consists of a simple Table that contains filenames and their cached result.
And when a User does something, like create a new post or like an existing post then we set the cached result to literally nothing.

We can check if the thing we want to render is empty, and if so then we re-create the page because it means something new was created.

It could happen like so:

```nim
# In routes.nim
var cachedPages: Table[string, string] = @[
  "some_file.html": "<p>some cached result</p>"
]

proc renderPage(filename) =
  if isEmptyOrWhitespace(cachedPages[filename]):
    # render it again and return the result
  else:
    return cachedPages[filename]

# Somewhere else. Like db.nim's addPost function

proc addPost(post:Post) =
  # Add post
  # blah blah
  cachedPages[filename] = "" # Make this empty so Potcode renders the page again
```

This is a very basic caching system, and I think it would work pretty well.
Though it might be better to use this for stylesheets instead or internal pages. Instead of user's webpages.

Or we could simply forego all of this and tell the user to configure the caching for their webserver.

Yeah no, I think asking users to configure their web servers would be a better idea. Since they typically have *way* better caching methods.

## Hash function table

So in order to help smoothly upgrade from old hashing methods, I have added an "kdf" column to the database schema.
This "kdf" column consists of a simple integer, which we will increment by one every time we have to switch to a new hashing algorithm or 
change the iterations that the current one uses.

 Number      Function       Iterations
--------   --------------   ----------------
  1      PBKDF2-HMAC-SHA512   210000
---------  --------------   ----------------

But how does this work? Imagine the following scenario: We have to upgrade from PBKDF2-HMAC-SHA512 to Argon2id or whatever.

When a user accesses their accounts, their "KDF" value is checked. If it is less than the new version then we can save their password and re-hash it
for them in the background. It could be implemented like so:

```pseudo
proc kdf_check(user: User, unhashed_password: string):
  if user.kdf < lib.kdf: # lib.kdf stores the currently-used and latest hash function version.
    # An update is in order!
    user.password = new_hashing_func(unhashed_password, user.salt)
    user.kdf = lib.kdf # Set this to stop re-hashing every login.
    db.update_user(user)
```

# Abandoning Potcode.

For the past few weeks, no real progress has been achieved and I frankly think this is because of Potcode, the whole concept is too much for a simple ActivityPub server.

Tumblr's model frankly sucks.
Yes, you can customize it however you want but I think most customization fans would be okay with a sensible default theme and the ability to customize the CSS and if we get rid of Potcode then we will cut about two months off of the deadline that used to be dedicated for Potcode development.

Also, most users don't know or care about Potcode, they just want an efficient, stable ActivityPub server. That's it.

# MRF

Pleroma's MRF feature is very amazing, and so naturally, Pothole has directly copied it. 

You can extend the MRF feature with your own policies/filters at run-time. Some custom MRF policy examples are provided [here](https://gt.tilambda.zone/o/pothole/server.git/tree/contrib?h=staging), how to enable custom MRF policies is documented [here](/wiki/mrf/)

Unfortunately, Pothole's MRF cannot be used to patch [extensibility issues](https://web.archive.org/web/20230207191702/https://spiderden.org/problems/software/interoperable_extensibility) as effectively as Pleroma's MRF can, since Pothole's MRF hooks get ran after processing the JSON into a Post/User/Activity object.

In general, MRF works like this for incoming data:
1. Pothole converts JSON into User/Post/Activity objects.
2. The MRF runs any suitable policies it can find.
3. It gets inserted into the database.
4. It's now available via the API or web frontend.

And MRF works like this for outgoing data:
1. The MRF runs any suitable policies it can find. (And some very basic pre-processing)
2. The objects get inserted into the database
3. Pothole converts the objects into JSON
4. Pothole sends the JSON out to other servers

So simple you could turn it into a flowchart! Yet, I am not gonna do that.

# Quark

This is the first entry in a while I assume, since a lot of information here is
old. In fact, git blame tells me the last change was by the original creator 6
months ago. It's only been 4 months since I took over, and it doesn't seem that
there were any special changes in those two months, the commit logs only tell me
that the creator was working on potholectl, more specifically the `dev`
subsystem.

Irregardless though, I, myself, have had a lot of rough design decisions that I
would have loved to document, if only I knew about the site directory. And
honestly, I'm having a bit of a blast exploring all the stuff I have found! It's
like an abandoned coal mine! Except without all of the danger maybe, and I am
learning a lot about the history of this project.

From what I can see in the site, there was a version published roughly 7 months
ago. The creator told me the schedule was supposed to be every six months (or
bi-annual if you're a fancy nerd), so this is already a month over deadline. But
I am abandoning that schedule until I get a stable release without ActivityPub
support.

That version, from 7 months ago, it was made for a single reason. It was because
the creator split the database logic and whatnot into its own library,
presumably because the code was messy and he wanted to write it like a library
since it would be cleaner.

But that split never lasted long, and I have no idea why. Now, I could ask the
creator, but it takes too long to actually get into contact. And we have to make
promises, appointments and ugh, it's too fucking annoying... What we can do
instead is hypothesize! From looking at the rest of the codebase, in its
historic form, it's clear that there was a huge split.

We know the creator split the codebase into two, possibly to ensure their style
would become more readable, but also, he moved the code away into a different
repository (What was the name of that repo? Idk)

I can already tell that this might've been too much for them, and so they
probably gave it up because of that. But, I do like the idea of making a
social-media library. So with that in mind! I bring to you: Quark!

It's the database logic, object definitions and everything packed into a
different location. I am already re-writing huge parts of the codebase to be
more independent, and less pothole-specific. The fun thing is that, soon enough
with better documentation, you could very well make your own social media server
(or anything that needs a User-Post-Activity framework) using this library!

Rather than putting it into its own repo, with its own release schedule and the
headaches of versioning two separate apps together. I will just put it into a
different folder on **this** repository. So it's easy for people to download,
and easy for people to contribute!

I think this can work, I feel like this has to work even! If I put in the work
then surely, it will work, right?  Well we will find out in the coming weeks
whether I can handle this or not, if not, then I will just merge the two
together.

Update from August: I cannot fathom just how quickly Quark got polluted with
Pothole-specific stuff. It's no longer the independent social-media library I
envisioned it to be but that's alright, there's still benefit in separating them
and I won't merge them back unless it's too complex for new developers.

## Post activities

Right now, Pothole only supports text-based messages. Which is okay, for the
most part and we can do a lot of interesting things if we add support for HTML
or Markdown, but the Fediverse has been moving on to more complex things, such
as polls, and media attachments and well, who knows what's next?

Post activities is what I have decided to call these things. These are
additional items, in addition to (or sometimes replacing) the `content` field.

In `quark/post.nim`, you can see the following:
```nim
type
  PostActivityType* = enum
    Poll, Media, Card

  ## See the "Post activities" section in DESIGN.md
  ## The explanation is too long to put it here, in code.
  PostActivity* = object
    case kind*: PostActivityType
    of Poll:
      id: string # The poll ID
      question: string # The question that was asked for the poll
      options: Table[string, seq[string]] # Key: Option, Val: List of users who voted for that option
      total_votes: int # Total number of votes
    of Media:
      media_id: string # Media attachments aren't actually stored in the db.
    else: discard
	  
  Post* = object
    ...
	extras*: seq[PostActivity]
```

There's a special PostActivity object in Quark whose structure changes depending
on what you're trying to parse.

So, if you're parsing a Poll, then you'll see questions, votes, and any other
extra info. If you're parsing media attachments then you'll get an ID that you
can pass onto your **own** storage layer for more info.

Anyway, in the database itself, we will have a text field.
It's a space-separated sequence of pairs. (In Nim-speak, `seq[(string, string)]`)

The first part of the pair corresponds to the type, fx. `poll` for polls,
`media` for media attachments.

The second part is the ID of that specific object, so, for polls, we would have
a separate database table specifically for polls. And the second part
corresponds to the ID of the poll.

And on the application side (or more specifically, `quark/db/posts.nim`) We run some extra logic to parse these activities and return (or insert) the data in an orderly manner.

What this means is that, from the database side, it's just a text field and a
database table. But on the application side, it's a dynamic object. And I feel
like this system can be extended to support new types of activities cleanly from
the application side.

You'd still have to modify getPost() and addPost() to properly parse and add the
Post object to the database but to make it slightly easier, I could add some
abstractions. (or not, we already have too many abstractions)

Right now though, I have to write the initial code for `getPost()` to retrieve
the extra post activities and the initial code for `addPost()` to actually
insert the new post activities.

But you also have to pay special care then, because, you shouldn't add new post
activities in the database directly, and you should instead just modify the
`extra` field in the Post object and let the database handle it for you.

So, in summary, This system would allow us to support new types of posts. And in
theory, we could even replace the dull, text-only `content` field with a sparkly
`content*: seq[PostActivity]` and just have a dull text-only `PostActivity`
object for normal text messages. And I might do that in the future, but not
now. I feel like that'd require a re-write of a LOT of code, and I don't feel
like doing that today.

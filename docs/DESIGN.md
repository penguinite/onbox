# Design choices

This is my personal development journal of Pothole. I describe the things and choices I take so that in the future I or other people will understand why they were added, how they work and when they were added.
I wanna try to make Pothole as light as possible. This means:

1. Reducing dependencies whenever possible.
2. Emphasizing readability over efficiency*
3. *: Readable code is often the most efficient code.

So here are the things I decided.

## Using Nim as a programming language.

Nim is an amazing language, I love the syntax so much! and I also love how fast it is, I tried this with Julia before but Julia is not fit for this task, it does not compile down to a binary without some workarounds and experimental plugins, which I do not like.

I also just love the documentation, the standard library is amazing, it has so many features.

Overall, the language is fun, safe and just plain awesome! It's like Python syntactically but more like C in terms of what you can do with it. 

## A custom config language instead of TOML.

Instead of depending on an extra library for configuration, we could do it ourselves.

So this is the hypothetical config language, you will notice that it is very similar to cgit.

```ini
# So here's how this language would look in theory:
# Lines beginning with # are comments
# You cannot do inline comments at all...
# I just don't think that's a good feature

# So let's try to configure something.
AdminEmail="admin@example.ph"

# Arrays are done like so:
# Very similar to Python, right?
# Arrays can only consist of Ints
InstanceRules=["Hail Tux!","Hail Me!","Hail Pothole!"]

# Arrays can also be multiline
# while regular values cannot.
InstanceRules=[
	"Hail Tux!",
	"Hail Me!",
	"Hail Pothole!",
]

# You might think, what about numbers?
# Pothole will convert strings to integers 
# if and when needed. Just wrap them
# in quotes. Or you can put them in like this:
TheShitsIGive=0

# Ok but what about booleans?
# Right here we accept numbers
# and strings as input but most
# importantly we make it case
# insensitive.

# All of these result in False
SignYourSoulAway="faLSe"
SignYourSoulAway="NO"
SignYourSoulAway=False
SignYourSoulAway=nO

# All of these result in True
SignYourSoulAway="true"
SignYourSoulAway="yes"
SignYourSoulAway=true
SignYourSoulAway=yes

# Make it so easy its hard to screw up...
```

You might think this looks lame or boring but it's easy to implement, probably faster than whatever TOML parser we're using and maybe even safer from a supply chain perspective. I would want to avoid using third-party modules as much as possible since I want to write my own code that I can understand.

### Make sure every request to config data is double-checked

So let me try to paint a scenario for you, which one is worse? Let's say you want to retrieve "PortNum" from the config file and so you send a request like-so:

```nim
var portnum:int = conf.getInt("PortNum")

web.startServer(app, portnum)
```

The program runs fine on your machine but complains on the other ones, it crashes! But what gives? Well it turns out "PortNum" is missing on some configuration. It's way easier for you as a developer to double-check that it exists first like so:

```nim
var portnum: int;

if conf.exists("PortNum"):
    portnum = conf.getInt("PortNum")
else:
    portnum = 3500

web.startServer(app, portnum)
```

I know it looks and sounds inefficient but this would be way easier than having to constantly debug missing things. if what you are implementing uses an optional configuration parameter then make sure to double-check it or Error out in peace!

Required options do not have to be double-checked, if they are not there then just crash and let the user deal with it! It's their fault after all...

### Parse keys/options as lowercase by default.

I don't think it makes sense to distinguish "PORT", "Port" and "port" in the configuration file, the configuration parser should ideally lowercase all values when adding them to `configTable` so that programs don't worry about if they are spelling it right.

## Startup routine

When you run Pothole, it will search for a config file to parse. The first thing it looks for is the `POTHOLE_CONFIG` environment variable which should specify a location to the config file that Pothole is supposed to run.

The second thing Pothole looks for is the `--config=` command-line option, you can specify a configuration file here too.

It falls back to searching for a file named `pothole.conf` in the current working directory.

Yada yada, at the end of the entire startup routine it should start a webserver at 3500 or a port specified in the config file, this means Pothole won't need root permissions but it also has to be proxied behind a much more powerful and stable web server (Nginx, Caddy etc.)

This approach is more secure.

## Database stuff

This section is all about the database, ie. what tables exist, their purpose and how they are formatted. Yada yada.

I am not trying to add ActivityPub support *yet* but I am trying to experiment with a small-scale social network app.

For now, I will be experimenting with sqlite databases, it's important to note that sqlite is quite different. See sqlite adaptations section.

*Note:* These SQL tables can maybe get a bit out of date. So please refer to `docs/db.sql` instead of this section for information about databases in Pothole! :)

To store users, we will need a separate table with the following columns:

```sql
CREATE TABLE IF NOT EXISTS users (
  id BLOB PRIMARY KEY, -- A randomly-generated ID.
  handle VARCHAR(65535) UNIQUE NOT NULL, -- User's actual username
  name VARCHAR(65535) NOT NULL, -- User's display name
  local BOOLEAN NOT NULL, -- A boolean indicating if the user is from here or from somewhere else.
  email VARCHAR(255), -- To store the user's email
  bio VARCHAR(65535), -- To store the user's biography
  password VARCHAR(65535), -- Stores a password hash, the hash is generated by crypto.hash() which is based on nimcrypto's PBKDF2 implementation
  salt VARCHAR(65535), -- A password salt, generated by data.newUser().
  is_frozen BOOLEAN, -- Indicates if a user is banned. This prevents them from logging in.
);
```

Meanwhile to store posts, we will need a separate table with the following columns:

```sql
CREATE TABLE IF NOT EXISTS posts (
  id BLOB PRIMARY KEY,
  sender VARCHAR(65535) NOT NULL,
  written TIMESTAMP NOT NULL,
  updated TIMESTAMP,
  recipients VARCHAR(65535),
  post VARCHAR(65535) NOT NULL
);
```

### Sqlite adaptations

Sqlite is quite different from MariaDB or PostgreSQL, for one, it does not care about text length. We can store a very long post in a varchar and sqlite does not care if it exceeds that length.

There is also no UUID datatype, we have to add it in as a string or blob (I chose blob)

What about recipients? In Akkoma, recipients are implemented as an ARRAY in the database. But we don't have that with sqlite so we have to use strings again, we *could* re-purpose conf.parseArray()

conf.parseArray() is too slow for this purpose though, since it was designed for an entirely different form of data. 
We could store recipients like so: `bob@bob.thebuilder,alice@alice.wonderland` since commas *cannot* be in domain names or usernames and then use strutils.split() to split the commas into a sequence that can be evaluated.

## Considerations for this project

I have to go soon but I wanted to write a bit about what I want this project to be, so that I do not lose track of myself. First and foremost, I want pothole to be a lightweight ActivityPub backend, I want to get as close to minimalism and speed as I can and then I want to turn Pothole into a customization heaven, what do I mean by that? Well I mean, something like Tumblr, where each user can design their own "blog" with real HTML and CSS, that sounds exciting to me!

Tumblr is going to implement ActivityPub support but most instances are probably going to block them considering how huge they are (hundreds upon hundreds of times bigger than mastodon.social and mastodon.social is already blocked by a huge portion of the Fediverse) so I wanted to re-create Tumblr but in a much easier-to-deploy form and way lighter form that actually lasts!

If this succeeds, then we will have a:
1. easy-to-deploy, lightweight, scalable CMS
2. with support for multiple users
3. and where each user can design their own blog
4. with support for ActivityPub.

WHAT MORE COULD ANYONE POSSIBLY WANT! But that's in the future, now, I have to work to achieve the first stage which is a stable, reliable ActivityPub backend that consumes little resources. I will optimize it AS MUCH AS POSSIBLE, to get it as fast as possible and to use as little memory as possible. Minimal systems are reliable systems and reliable systems are secure systems.
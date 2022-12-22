# Design choices

This is my personal development journal of Pothole. I describe the things and choices I take so that in the future I or other people will understand why they were added, how they work and when they were added.
I wanna try to make Pothole as light as possible. This means:

1. Reducing dependencies whenever possible.
2. Emphasizing readability over efficiency*
3. *: Readable code is often the most efficient code.

So here are the things I decided.

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

To store users, we will need a separate table with the following columns:

```sql
CREATE TABLE users (
	id BLOB PRIMARY KEY,
	name VARCHAR(255),
	email VARCHAR(255),
	handle VARCHAR(65535)
);
```

Meanwhile to store posts, we will need a separate table with the following columns:

```sql
CREATE TABLE posts (
    id BLOB PRIMARY KEY,
    sender VARCHAR(65535),
	written TIMESTAMP,
	recipients VARCHAR(65535),
    post VARCHAR(65535)
);
```

### Sqlite adaptations

Sqlite is quite different from MariaDB or PostgreSQL, for one, it does not care about text length. We can store a very long post in a varchar and sqlite does not care if it exceeds that length.

There is also no UUID datatype, we have to add it in as a string or blob (I chose blob)

What about recipients? In Akkoma, recipients are implemented as an ARRAY in the database. But we don't have that with sqlite so we have to use strings again, we *could* re-purpose conf.parseArray()

conf.parseArray() is too slow for this purpose though, since it was designed for an entirely different form of data. 
We could store recipients like so: `bob@bob.thebuilder,alice@alice.wonderland` since commas *cannot* be in domain names or usernames and then use strutils.split() to split the commas into a sequence that can be evaluated.
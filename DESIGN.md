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

```
# So here's how this language would look in theory:
# Lines beginning with # are comments
# You cannot do inline comments at all...
# I just don't think that's a good feature

# So let's try to configure something.
AdminEmail="admin@example.ph"

# Arrays are done like so:
# Very similar to Python, right?
# Except this time, quotes are absolutely neccessary
InstanceRules=[
	"Hail Tux!",
	"Hail Me!",
	"Hail Pothole!",
]

# You might think, what about numbers?
# Not needed. Pothole will convert strings
# to integers if and when needed. Just
# wrap them in quotes OR:
# Add them like this
TheShitsIGive=0

# Ok but what about booleans?
# Right here we accept numbers
# and strings as input but mos
# importantly we make it case
# insensitive.

# All of these result in False
SignYourSoulAway="faLSe"
SignYourSoulAway="NO"
SignYourSoulAway=False
SignYourSoulAway=nO
SignYourSoulAway=1

# All of these result in True
SignYourSoulAway="true"
SignYourSoulAway="yes"
SignYourSoulAway=true
SignYourSoulAway=yes
SignYourSoulAway=0

# Make it so easy its hard to screw up...
```

You might think this looks lame or boring but it's easy to implement, probably faster than whatever TOML parser we're using and maybe even safer from a supply chain perspective.

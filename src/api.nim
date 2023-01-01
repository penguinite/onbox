# Unused for now, but to be used for MastoAPI implementation later in the project
# This file could also include some definitions or procedures specifically intended for ActivityPub support
# Or we could move it to a new file called ap.nim

from std/json import JsonNode
import lib

# An extension of a user.
type
  Actor* = object
    inbox*: string
    outbox*: string

# This thing represents activities
type
  Activity* = object
    kind*: string # Stores what type the Activity is (Create, Delete etc.) (NOTE: Nim already reserves "type" so we cannot use that.)
    id*: string # Stores the location of the Activity
    to*: seq[string] # A sequence of recipients.
    actor*: string  # A string containing the actor
    date*: string # A timestamp of when the Activity was created
    updated*: string # A timestamp of when then Post was last edited
    data*: Post # The actual post/object

type
  ActivityRef* = ref Activity
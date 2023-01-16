# Unused for now, but to be used for MastoAPI implementation later in the project
# This file could also include some definitions or procedures specifically intended for ActivityPub support
# Or we could move it to a new file called ap.nim

import lib

# Temporary Actor
# Will be converted to full User object if it passes validation.
type
  Actor* = ref object
    inbox*: string # An actors inbox
    outbox*: string # An actors outbox

# This thing represents activities
# It will be stored as a Post
type
  Activity* = ref object
    kind*: string # Stores what type the Activity is (Create, Delete etc.) (NOTE: Nim already reserves "type" so we cannot use that name.)
    id*: string # Stores the location of the Activity
    to*: seq[string] # A sequence of recipients.
    actor*: string  # A string containing the actor
    date*: string # A timestamp of when the Activity was created
    updated*: string # A timestamp of when then Post was last edited
    data*: Post # The actual post/object


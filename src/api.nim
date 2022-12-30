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
# Maybe in the future we could
type
  Activity* = object
    id*: string
    sender*: string 
    written*: string 
    updated*: string
    recipients*: seq[string]
    unknown*: JsonNode # Stores unknown AP parameters and data.

type
  ActivityRef* = ref Activity
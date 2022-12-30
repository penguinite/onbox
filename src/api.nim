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
# Post data type, which represents posts in the database.
# -    id: string      =    A OID that represents the actual post (Db: blob primary key)
# -    sender: string  =    A string containing the sender of the post (Db: varchar not null)
# -    written: string =    A timestamp of when the post was written (Db: timestamp not null)
# -    updated: string =    A timestamp of when the post was updated (or null if it wasn't) (Db: timestamp)
# -    post: string    =    Actual JSON Data for the post (Db: varchar)
# - recipients:seq[str]=    A sequence of recipients (Db: varchar)
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
# src/

Folder that contains all the source code.

1. conf.nim: Functions for fetch configuration file data and parsing it.
2. crypto.nim: Functions related to cryptography or randomness.
3. db.nim: A bit of code that switches between sqlite and postgres's database backends in compile-time
4. db/sqlite.nim: The sqlite database backend
5. db/postgres.nim: The postgres database backend
6. lib.nim: Shared functions, values and data used across the library.
7. post.nim: Functions related to the Post object. (This also contains the type definition)
8. debug.nim: Procedures for debugging, right now this only creates fake users and posts.
9. user.nim: Functions related to the User object. (This also contains the type definition)

Probably coming soon:

10. activitypub.nim: Helper functions for dealing with ActivityPub and parsing JSON-LD
11. api.nim: The MastoAPI layer.

## Why so much?

It's not that bad honestly, most of the code is good-quality and each module is only around ~200 lines of code on average but I want to categorize it for easy development and easy use. This is why so many modules exist.
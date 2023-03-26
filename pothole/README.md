# src/

Folder that contains all the source code.

1. conf.nim: Functions for fetching data from the configuration file
2. crypto.nim: Functions related to cryptography or random number generation
3. db.nim: A wrapper for database backends.
4. db/*.nim: The actual bits of code that do the database operations (Also known as backends)
5. lib.nim: Shared functions, values and data across the app (Contains the User & Post type definitions)
6. post.nim: Functions related to the Post object.
7. potcode.nim: A parser for Potcode (Used for static pages & user profiles)
8. test.nim: This module adds fake posts and users, it is primarily used in testing and it is completely absent from production builds.
9. user.nim: Functions related to the User object.
10. potholectl.nim: A CLI program that provides low-level access to Pothole's internals.

Probably coming soon:

11. activitypub.nim: Helper functions for dealing with ActivityPub and parsing JSON-LD
12. api.nim: The MastoAPI layer.

## Why so much?

It's not that bad honestly, most of the code is good-quality but I want to categorize it for easy development, this is why so many modules exist.
# src/

Folder that contains all the source code.

1. assets.nim: Functions for fetching data from the filesystem (Static assets, User themes and User uploads)
2. conf.nim: Functions for fetching data from the configuration file
3. crypto.nim: A wrapper for nimcrypto's PBKDF2-HMAC-SHA512 implementation. And also a randomString function.
4. db.nim: A wrapper for database backends.
5. db/*.nim: The actual bits of code that do the database operations (Also known as backends)
6. lib.nim: Shared functions, values and data across the app (Contains the User & Post type definitions)
7. post.nim: Functions related to the Post object.
8. potcode.nim: A parser for Potcode (Used for static pages & user profiles)
9. pothole.nim: The main app, this is what gets compiled.
10. routes.nim: Routes for the app, it also contains the logic for registering and logging in
11. test.nim: This module adds fake posts and users, it is primarily used in testing and it is completely absent from production builds.
12. user.nim: Functions related to the User object.

Probably coming soon:

13. activitypub.nim: Helper functions for dealing with ActivityPub and parsing JSON-LD
14. api.nim: The MastoAPI layer.

## Why so much?

It's not that bad honestly, most of the code is good-quality but I want to categorize it for easy development, this is why so many modules exist.
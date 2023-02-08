# src/

Folder that contains all the source code.

1. assets.nim: Functions for fetching data from the filesystem (Static assets, User themes and User uploads)
2. conf.nim: Functions for fetching data from the configuration file
3. crypto.nim: A wrapper for nimcrypto's PBKDF2-HMAC-SHA512 implementation. And also a randomString function.
4. data.nim: Functions for validating the Post and User object.
5. db.nim: Functions for storing, retrieving, updating and deleting items in the database
6. lib.nim: Shared functions, values and data across the app (Contains the User & Post type definitions)
7. pothole.nim: The main app, this is what gets compiled.
8. routes.nim: Routes for the app, it also contains the logic for registering and logging in

Probably coming soon:

11. syntax.nim: A parser for Potcode (User theme syntax)
12. activitypub.nim: Helper functions for dealing with ActivityPub and parsing JSON-LD

## Why so much?

It's not that bad honestly, most of the code is good-quality but I want to categorize it for easy development, this is why so many modules exist.
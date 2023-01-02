# src/

Folder that contains all the source code.

1. api.nim: This module isn't complete and will be implemented in the future. It contains routes and procedures for the MastoAPI layer.
2. assets.nim: Functions for fetching data from the filesystem (Static assets, User themes and User uploads)
3. conf.nim: Functions for fetching data from the configuration file
4. crypto.nim: A wrapper for nimcrypto's PBKDF2-HMAC-SHA512 implementation. And also a randomString function.
5. data.nim: Functions for validating the Post and User object.
6. db.nim: Functions for storing, retrieving, updating and deleting items in the database
7. lib.nim: Shared functions, values and data across the app (Contains the User & Post type definitions)
8. pothole.nim: The main app, this is what gets compiled.
9. routes.nim: Routes for the app, it also contains the logic for registering and logging in
10. web.nim: Functions to generate static content for user profiles, web pages and so on.

Probably coming soon:

11. syntax.nim: A parser for Potcode (User theme syntax)
12. activitypub.nim: Helper functions for dealing with ActivityPub and parsing JSON-LD

## Why so much?

It's not that bad honestly, most of the code is good-quality but I want to categorize it for easy development, this is why so many modules exist.
---
title: "Build options"
description: "This page documents all the different build options that are available when building Pothole."
---

This page documents all the different build options we have. You should be able to just append this directly to the `nimble build` command and have it work.

2. `-d:phLang`, optional (defaults to "en"), Accepts a string.

This flag tells Pothole what language to use for its instance pages. 

The following languages are available:
| language | code |
|----------|------|
| English  | en |
| Danish | da |

Though you can simply change the static assets at runtime. So this option is not all that important.

3. `-d:phVersion`, optional, Accepts a string.

This flag allows you to change the version hardcoded into pothole.

10. `-d:phPrivate`, optional, Accepts no arguments.

*Note:* This flag is currently experimental as in, it's being developed right now and it does not do very much.

*Note:* This flag might make Pothole a tiny bit slower, both in compilation and runtime.

**Warning:** Make sure your web server is also configured to not record IP addresses, otherwise this flag is pretty much useless.

This flag tells pothole to be more private, by minimizing as much data collection as possible and allowing users to be more anonymous. If you are setting up a large-scale instance, and there is no guarantee that all your users will follow good security practices then this flag is not recommended, since it will make it harder to investigate account breaches.

If you are setting up an instance for yourself, and you use good security practices then using this flag is up to you. It does not weaken Pothole's authentication mechanisms, it just records less information about sensitive things.

This flag is primarily for invesigative journalists or individuals being threatened by powerful regimes, where privacy is a neccessity and recording information can be a matter of life and death-

Features:

* Stops recording of logged-in users in debug logs.
* Stops email requirement for signing up. (Users with no email address **cannot** use the forgotten password prompt.)
* Hides Pothole's version number (By setting it to a random number in the API and 0 everywhere else.)

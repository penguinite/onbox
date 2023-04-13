# libpothole

Essential libraries for the Pothole server/backend.

*Note:* This is the main branch, where active development on Pothole is done. You are most likely looking for the `stable` branch, which is better suited for server environments, you can find it [here](https://codeberg.org/pothole/pothole/src/branch/stable).

**Note:** Pothole and thus libpothole is very much a work-in-progress software project. Lots of implementation details are being figured out just now and are thus likely to change over time. In other words, this is pre-alpha or even *research* stage. 

## What is Pothole?

Pothole is a social media backend written in Nim, it's designed to be simple & fast. It has unique features such as allowing user-profiles to be written with custom HTML & CSS (Pothole's features can be embedded using a language we call [Potcode](https://codeberg.org/pothole/docs/src/branch/master/dev/POTCODE.md)), Pothole is more reminiscent of Tumblr in this sense since it allows you to fully customize your profile.

Pothole federates to other servers using the ActivityPub protocol which means you can communicate to users on Mastodon, Akkoma, Misskey or whatever website that implements it. Pothole is also compatible with Mastodon's API interface, so your clients, frontends and bots should work with little to no changes.

## What is *this* then?

This is libpothole, it basically contains all the nifty logic for storing, processing and handling data such as Users, Posts and generic Activities. The main pothole server relies on this as a dependency since this library is the brains of the operation and without it Pothole would simply not work.

## How do I use this library?

Library documentation is an on-going effort that is yet to be complete. But you can simply browse the source code and read what each function does. We try to keep the code as readable as possible.
The `README.md` file inside of the `pothole/` folder tells you what each module is for.

You can generate documentation by running `nimble docs`, this will generate HTML documentation in a separate directory named `htmldocs`

When it comes to importing a module into your app, you should have this library installed and you should use these snippets:

```
import pothole/MODULE # Replace module with your module obviously...
import pothole/conf # For configuration file parsing etc.
import pothole/[conf, user, post] # Imports multiple modules at the same time.
```

There is a `libpothole.nim` module but we do not recommend importing it as you might not use all of the functions inside of it and you will simply slow your build process.

## Why is Pothole and libpothole separate?

Well it's primarily to help foster a unique ecosystem of servers. If you want to build your own ActivityPub server then you can use this as a base and code anything you want in addition! And it's also done to separate `potholectl` from the main server repository since those programs are very different from each other and should not be in the same place at all.

We don't want this useful piece of software to be locked inside of a single homogenous server application, we want to allow developers to use this library if they want to.

Oh and it also means we can easily test this out.

I know it seems a bit confusing but you, as a user, don't really have to worry about this change/separation. You can still call the entirety of this and the server program "Pothole", it doesn't really matter and people will in 99% of cases know what you are talking about.

## What is the release cycle?

Well, this library follows the same versioning and release cycle as the regular Pothole server program. The version should always be bumped unless there is no measurable difference between the current codebase and the previous one. This is to reduce confusion.

## Copyright

Copyright © Leo Gavilieau 2022-2023

All code is licensed under the GNU General Public License version 3 or later. (File: `LICENSES/GPL.txt`)
All generated documentation is licensed under the Creative Common Attribution-ShareAlike 4.0 International license (File: `LICENSES/CC.txt`)
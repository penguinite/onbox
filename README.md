# libpothole

Essential libraries for the Pothole microblogging backend and related projects.

*Note:* Pothole and thus libpothole is very much a work-in-progress. Lots of implementation details are being figured out just now and are thus likely to change over time. In other words, this is pre-alpha or even *research* stage. 

*Note:* This is the `staging` branch which contains bleeding-edge library logic, however we do not recommend this for production-ready apps at all as this might be less table. So pick your poison! stability or bleeding-edge (or pick a specific feature branch to test out a feature if you are developing for it.)

## What is Pothole?

Pothole is a microblogging server written in Nim, it's designed to be simple & fast. It has unique features such as allowing user-profiles to be customized. Pothole is far more reminiscent of Tumblr in this sense since it allows you to fully customize your profile and unleash your creativity in ways that other microblogging websites do not allow for.

Pothole federates to other servers using the ActivityPub protocol which means you can communicate to users on Mastodon, Akkoma, Misskey or whatever website that implements ActivityPub. Pothole is also compatible with Mastodon's API interface, so your clients, frontends and bots should work with little to no changes.

## What is *this* then?

This is libpothole, it basically contains all the nifty logic for storing, processing and handling data such as Users, Posts and generic Activities. The main pothole server relies on this as a dependency since this library is the brains of the operation and without it Pothole would simply not work.

Think of it like a glass of water. Sure, you can drink the water without the glass but you would just make a mess unless you create your own cup (In this analogy, the water is the library and the cup is the server program) 

## How do I use this library?

Library documentation is an on-going effort that is yet to be complete. But you can simply browse the source code and read what each function does. We try to keep the code as readable as possible.

The `README.md` file inside of the `src/` folder tells you what each module is for.

You can generate documentation by running `nimble docs`, this will generate HTML documentation in a separate directory named `htmldocs`

When it comes to importing a module into your app, you should have this library installed and you should use these snippets:

```
import libpothole/MODULE # Replace module with your module obviously...
import libpothole/conf # For configuration file parsing etc.
import libpothole/[conf, user, post] # Imports multiple modules at the same time.
```

**Warning when updating to newer versions:** Don't just use newer versions of libpothole! Always double-check the release notes of any libpothole release for breaking changes such as database migrations, and make sure to inform your users of the same!

## Why is Pothole and libpothole separate?

Well it's primarily to help foster a unique ecosystem of servers. If you want to build your own ActivityPub server then you can use this as a base and code anything you want in addition! And it's also done to separate `potholectl` from the main server repository since those programs are very different from each other and should not be in the same place at all.

We don't want this useful piece of software to be locked inside of a single monolithic server application, we want to allow developers to use this library if they want to. Oh and it also means we can easily test this out for any bugs, security issues and so on.

I know it seems a bit confusing but you, as a user, don't really have to worry about this change/separation. You can still call the entirety of this and the server program "Pothole", it doesn't really matter and people will in 99% of cases know what you are talking about.

In short, the decision to separate libpothole from pothole's main server repository means we can focus on re-writing libpothole to have good clean code, instead of returning to the old mess containing un-factorable code and circular dependencies.

## What is the release cycle?

Well, this library follows the same versioning and release cycle as the regular Pothole server program. This is to reduce confusion. However, new versions are released as quickly as possible if they address a security issue or a critical bug.

Please read our development workflow article for more information (The article is available at [this location](https://xmoo.vern.cc/pothole/contrib/workflow/)) (Ignore the parts about mailing lists, tilambda does not *yet* have proper Email infrastructure in place)

## Copyright

Copyright © Leo Gavilieau 2022-2023

All code is licensed under the GNU General Public License version 3 or later. (File: `LICENSES/GPL.txt`)
All generated documentation is licensed under the Creative Common Attribution-ShareAlike 4.0 International license (File: `LICENSES/CC.txt`)

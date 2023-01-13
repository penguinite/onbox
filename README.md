# Pothole ![Build status](https://ci.vern.cc/api/badges/xmoo/pothole/status.svg)

A lightweight ActivityPub backend written in Nim. Pothole allows you to control your digital life!

*Note:* This is the main branch, It's not as stable as the `stable` branch but it does include newer features. For server environments, you should use the `stable` branch.

## Does it work?

No. You are better off using [Akkoma](https://akkoma.social/) or [GoToSocial](https://gotosocial.org/).

It might be someday in the future more stable, but I am busy with other things and this is made in a programming language I am not very familiar with. So this is the reason why it's not ready yet.

### But I still want to use it

Well then head on to the compilation section, but don't expect it to fully work out-of-the-box, configuration is required.

## Compilation

Pothole is written in Nim, so you'll need the nim compiler, your favorite C compiler (`gcc` and `clang` work pretty well) and Nimble.

Simply run `nimble build` to build Pothole, by default it will build with sane options and be optimized for speed rather than size.

It will also install any and all dependencies for you!

### Makefile-based compiling

The makefile is there for developer use as it includes common targets with developmental settings. You can build with release settings using `make all`

## Copyright

Copyright © Leo Gavilieau 2022-2023

Licensed under GNU Affero General Public License version 3 or later.

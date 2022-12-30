# Pothole

A lightweight ActivityPub backend writte in Nim. 

*Note:* This is the stable branch, which as the name suggests, is stable and should be good enough for production environments. This branch however might have less features than the master branch, pick your poison: bleeding-edge or stability.

Make sure to build using `nimble build`!

## Does it work?

No. You are better off using [Akkoma](https://akkoma.social/) or [GoToSocial](https://gotosocial.org/).

It might be someday in the future more stable, but I am busy with other things and this is made in a programming language I am not very familiar with. So this is the reason why it's not ready yet.

### But I still want to use it

Well then head on to the compilation section, but don't expect it to fully work out-of-the-box, configuration is required.

If I had to give an estimate, i'd say that Pothole is 0.05% towards reaching its goal of being a barely-working lightweight ActivityPub backend.

## Compilation

Pothole is written in Nim, so you'll need the nim compiler, your favorite C compiler (`gcc` and `clang` work pretty well) and Nimble.

Simply run `nimble build` to build Pothole, by default it will build with sane options and be optimized for speed rather than size.

It will also install any and all dependencies for you!

## Installation

For now, installation relies on Nimble's built-in installer, I don't know how it works but running `nimble install` builds the project and adds it to your PATH, if you are building for yourself then this is probably the best method.

But make sure to copy the example configuration file since Nimble does not do it for you, and also make sure to edit it for your own needs.

## Running as-is

You can execute `make test` to compile Pothole with debug options and run it instantly. This is more intended for developer testing and it is not recommended for average users. **Note:** This method requires GNU make or any decent `make` implementation. And it will also compile Pothole with debugging settings which is generally not recommended for servers.

But if you do not want to install `make` then you can use the following command to execute and run Pothole as-is: `nim r  -d:release --opt:speed --threads:on --stackTrace:on src/pothole.nim`. 
## Copyright

Copyright © The Pothole Project 2022

Licensed under GNU Affero General Public License version 3 or later.

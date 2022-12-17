# Pothole

A lightweight ActivityPub backend.

## Does it work?

No. You are better off using [Akkoma](https://akkoma.social/) or [GoToSocial](https://gotosocial.org/).

It might be someday in the future more stable, but I am busy with other things and this is made in a programming language I am not very familiar with. So this is the reason why it's not ready yet.

### But I still want to use it

Well then head on to the compilation section

## Compilation

Pothole is written in Nim, so you'll need the nim compiler, your favorite C compiler, GNU make or any decent `make` implementation.

Simply run `make all` to build Pothole, by default it will build with sane options and be optimized for speed rather than size.

## Running as-is

You can execute `make test` to compile Pothole with debug options and run it instantly. This is more intended for developer testing and it is not recommended for average users.

## Copyright

Copyright © The Pothole Project 2022

Licensed under GNU Affero General Public License version 3 or later.
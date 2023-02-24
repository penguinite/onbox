# Pothole

A lightweight ActivityPub backend written in Nim. Pothole allows you to control your digital life!

*Note:* This is the main branch, where active development on Pothole is done. You are most likely looking for the `stable` branch, which is better suited for server environments, you can find it [here](https://git.vern.cc/pothole/pothole/src/branch/stable).

## What is it?

Pothole is an ActivityPub backend written in Nim, it's designed to be simple & fast. It has unique features such as allowing user-profiles to be written with custom HTML & CSS (in a language we call [Potcode](https://git.vern.cc/pothole/docs/src/branch/master/dev/POTCODE.md)), Pothole is more reminiscent of Tumblr in this sense, Pothole is basically decentralized, fast Tumblr.

Pothole primarily implements ActivityPub, but Pothole is also compatible with Mastodon and Akkoma, it also implements the Mastodon API with some custom extensions. So it should work with all of your clients and bots with little to no changes needed. 

## Does it work?

No. You are better off using [Akkoma](https://akkoma.social/) for a stable backend or [GoToSocial](https://gotosocial.org/) for a light-as-air backend.

Development is slow because creating anything remotely like this is incredibly difficult, I am trying to emphasize speed & safety over shiny features, and that means I keep planning ahead for new things and that's why this is taking so long. Pothole is still in early-development, it is still in it's design phase! Though [progress on multiple fronts has been made](https://git.vern.cc/pothole/pothole/activity/monthly)

### But I still want to use it

Well then head on to the compilation section, but don't expect it to fully work out-of-the-box, configuration and setup is required. This will be documented someday.

## Compilation

Pothole is written in Nim, so you'll need the [nim compiler](https://nim-lang.org/), your favorite C compiler (`gcc` is recommended) and Nimble.

Simply run `nimble build` to build Pothole, by default it will build with sane options and be optimized for speed rather than size.

It will also install any and all dependencies for you!

### Makefile-based compiling

The makefile is there for developer use as it includes common targets with developmental settings. You can build with release settings using `make all`

## Copyright

Copyright © Leo Gavilieau 2022-2023

Licensed under GNU Affero General Public License version 3 or later.

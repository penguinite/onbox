# Pothole

A lightweight, federated and powerful microblogging server written in Nim. Pothole allows you to share your digital life without the constraints of modern, commercial social media!

*Note:* Pothole is a work-in-progress. Lots of implementation details are being figured out just now and are thus likely to change over time. In other words, this is pre-alpha or even *research* stage. 

*Note:* This is the `main` branch which contains a bleeding-edge codebase, which isn't stable at all for production environments, consider downloading the `stable` branch instead which is more stable. (Although, there is no `stable` branch as of yet since nothing works yet) So pick your poison! stability or bleeding-edge (or pick a specific feature branch to test out a feature if you are a developer.)

## What is Pothole?

Pothole is a microblogging server written in Nim, it's designed to be simple & fast. It has unique features such as allowing user-profiles to be customized. Pothole is far more reminiscent of Tumblr in this sense since it allows you to customize your profile and unleash your creativity in ways that other microblogging services simply cannot do.

Pothole federates to other servers using the ActivityPub protocol which means you can communicate to users on Mastodon, Akkoma, Misskey or whatever website that implements ActivityPub. Pothole is also compatible with Mastodon's API interface, so your clients, frontends and bots should work with as few changes as possible.

## Does it work?

No. You are better off using [Pleroma](https://pleroma.social/) for a stable backend or [GoToSocial](https://gotosocial.org/) for a light-as-air backend.

Development is slow because creating anything remotely like this is incredibly difficult, I am trying to emphasize speed & safety over shiny features, and that means I keep planning ahead for new things and that's why this is taking so long. Pothole is still in a sort-of research state, I believe it will stabilize over the coming months but I can't guarantee anything.

## How do I use Pothole?

Install [nim](https://nim-lang.org/), your favorite C compiler (gcc is recommended, clang might not be optimal) and nimble. Run `nimble -d:release build` and it will build with release settings. (You will also need to install postgres as a library and database server somewhere.)

Pothole's main database is postgres, and so it expects an actively-running postgres server process in the background to work. You can change the database connection settings by editing the `pothole.conf` configuration file. If you don't want to (or can't) install postgres but you have access to docker, then you can run the `potholectl db docker` command to generate a postgres database docker container configured for pothole. `potholectl` can be found in the `build/` folder when you finish building pothole.

Assuming you did not change the port that pothole uses in the configuration file, head over to [127.0.0.1:3500](http://127.0.0.1:3500) and experience its glory! This is a basic demonstration setup, a proper setup procedure with reverse proxying and media proxy can be found is coming soon!

## Copyright

Copyright © Leo Gavilieau <xmoo@privacyrequired.com> 2022-2023
Copyright © penguintie <penguinite@tuta.io> 2024

Licensed under GNU Affero General Public License version 3 or later. A copy is is available as the `LICENSE` file.
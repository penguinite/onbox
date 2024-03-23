# Pothole

A lightweight, federated and powerful microblogging server written in Nim. Pothole allows you to control your digital life!

*Note:* Pothole is a work-in-progress. Lots of implementation details are being figured out just now and are thus likely to change over time. In other words, this is pre-alpha or even *research* stage. 

*Note:* This is the `staging` branch which contains a bleeding-edge codebase, however we do not recommend this for production environments at all as this might be less stable. So pick your poison! stability or bleeding-edge (or pick a specific feature branch to test out a feature if you are a developer.)

## What is Pothole?

Pothole is a microblogging server written in Nim, it's designed to be simple & fast. It has unique features such as allowing user-profiles to be customized. Pothole is far more reminiscent of Tumblr in this sense since it allows you to fully customize your profile and unleash your creativity in ways that other microblogging services simply cannot do.

Pothole federates to other servers using the ActivityPub protocol which means you can communicate to users on Mastodon, Akkoma, Misskey or whatever website that implements ActivityPub. Pothole is also compatible with Mastodon's API interface, so your clients, frontends and bots should work with little to no changes.

## Does it work?

No. You are better off using [Akkoma](https://akkoma.social/) for a stable backend or [GoToSocial](https://gotosocial.org/) for a light-as-air backend.

Development is slow because creating anything remotely like this is incredibly difficult, I am trying to emphasize speed & safety over shiny features, and that means I keep planning ahead for new things and that's why this is taking so long. Pothole is still in a sort-of research state, I believe it will stabilize over the coming months but that it will truly be considered alpha software next year.

## How do I use Pothole?

Install [nim](https://nim-lang.org/), your favorite C compiler (we recommend gcc) and nimble. Run `nimble build` and it will build with sane options and parameters by default.

Pothole expects a configuration file in its current working directory (or in an environment variable), it should be present in the build folder where you can simply modify it and then run the pothole executable to get a working server.

In addition, you will need to have a Postgres database server running. You can quickly start up a server (for developmental or testing purposes) with potholectl, like so:

```sh
nimble run potholectl dev setup

# To clear the database, you can run:
nimble run potholectl dev clean

# For more dev-related commands, run:
nimble run potholectl dev
```

Assuming you did not change the port that pothole uses in the configuration file, head over to [127.0.0.1:3500](http://127.0.0.1:3500) and experience its glory!

## Copyright

Copyright © penguintie <penguinite@tuta.io> 2024
Copyright © Leo Gavilieau <xmoo@privacyrequired.com> 2022-2023

In January 2023, I was asked to maintain this project by Leo Gavilieau, it seems as if they no longer wanted it. So I am the new project leader!

Licensed under GNU Affero General Public License version 3 or later. A copy is is available as the `LICENSE` file.

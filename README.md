# Onbox

Onbox (formerly Pothole) is a lightweight and powerful backend social networking server written in Nim. It allows you to share your digital life without the constraints of modern, commercial social media!

*Note:* Onbox is a work-in-progress. A lot of features are missing and the codebase is still likely to change. In other words, this is still in pre-alpha stage. Using it right now isn't recommended.

*Note 2:* This is the `main` branch which contains a bleeding-edge codebase, which isn't stable at all for production environments. There will be a `stable` branch for you to download from when this inevitably stabilizes.

## What is Onbox?

A social media website (such as Tumblr, Twitter and so on) usually consists of two parts: The frontend and the backend. The frontend is the part of the website that is visible to everyone, it's the homepage, it's the app, it's what you usually use to post new messages. The second part is the backend which handles everything internally, There is *no* user interface at all, unless it's related to authentication. Onbox is the latter, it's a backend program that processes messages but it does not show them to you via a website or an app.

The main goal with Onbox was to create a simple, lightweight server that is as efficient as possible. When you set it up, it immediately starts processing messages, without any troubles. A backend server is useless by itself so Onbox also has Mastodon API compatability, which means you can install just about any [Mastodon client](https://joinmastodon.org/apps) and it should work out of the box with ease!

### What's with the name?

This project was formerly called "Pothole"; which is a terrible name for three reasons:

1. It doesn't describe a positive thing, it's usually a negative thing
2. The name doesn't describe anything about this project
3. It could make up for the above reasons by being a clever pun or something, but it isn't which makes everything about it much more infuriating.

Onbox was chosen as the new name, it is a portmanteau of "Online" and "box", which I feel describes some aspects about it way better than the old name, it's basically a small box you open to make your communications go online. Also, there is a sort-of clever pun in the pronounciation, "Onbox" is pronounced the way as "unbox": to use Onbox, you'd have to unbox it.

## Does it work? Should I use it?

Sadly, This project is still incomplete and it is way too low-level to use comfortably. You are better off using [Pleroma](https://pleroma.social/) or [GoToSocial](https://gotosocial.org/) which are way more mature and offer nearly everything you'd want.

Onbox is a low-level program, it can't setup a proper social media website on its own. You would need to setup a client or a frontend and currently this kinda thing is incredibly difficult to do since there is no documentation on how to do it and I can't offer much help because there are so many clients/frontends to consider.

In addition, Onbox is *still* in development, a lot of things haven't been fully implemented yet and the codebase still changes constantly. If I **have** to give an estimate as to when it will become more stable, then it'd be early 2026. There is still a lot of work to be done.

## How do I use Onbox?

You can find pre-built binaries [here](https://ftp.penguinite.dev/rosecli/), when you extract you'll find a copy of `onbox` which is the actual server daemon, `onboxctl` which is used for common maintenance tasks and an example configuration file that you're expected to edit.

These binaries are built for Linux x64_86 glibc (meaning that they don't work with Alpine), they are sadly not reproducible (switching to musl libc might improve reproducibility, decrease attack surface, increase compatability and improve performance, and I am considering it.) 

### How do I compile Onbox myself?

Note: *Compilling on non-Linux platforms might not be supported as I am a solo developer and can only support one platform at a time.*

Dependencies:
- Compile-time: libpostgres headers
- Run-time: Postgresql server

Install the latest version of [nim](https://nim-lang.org/), your favorite C compiler (gcc is recommended) and nimble. Run `nimble build -d:release` and it should work all by itself.

The database server used by Onbox is [postgresql](https://www.postgresql.org/) and so, Onbox expects an actively-running postgres server process in the background to work. You can change the connection settings by editing the `onbox.conf` configuration file.

If you don't want to (or can't) install postgres but you have access to docker, then you can run the `onboxctl db docker` command to generate a postgres database docker container. `onbox` can be found in the `build/` folder when you finish building it.

Assuming the port in the config file isn't changed, Onbox starts running at `http://localhost:3500`, but do know that Onbox is meant to be a backend server. For a proper user interface, you need to supplement it with a client/frontend. And this is also just a basic demonstration setup, a proper setup would include a reverse proxy and a media proxy.

## Copyright

Copyright © penguinite <penguinite@tuta.io> 2024-2025

Copyright © Leo Gavilieau <xmoo@privacyrequired.com> 2022-2023

Licensed under GNU Affero General Public License version 3 or later. A copy is is available as the `LICENSE` file.

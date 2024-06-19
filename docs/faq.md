---
title: "Frequently Asked Questions"
---

This webpage contains questions that you as a user might find helpful.

# How do I build Pothole?
Follow the [compilation guide](/wiki/compile/) in our wiki.

# How do I install Pothole?
Follow the [installation and setup guide](/wiki/install/) in our wiki

# When will Pothole be finished?

Developing a microblogging backend is quite difficult, especially one with federation.
but fortunately, progress on multiple fronts has been made over the past weeks,
and with each passing day, we get closer and closer to achieving Pothole Perfection.

# What is potholectl?


potholectl is a control program for Pothole,
it allows system administrators to perform tasks using the CLI,
it is also used for database migrations between different versions of pothole.
It can be used to perform the following tasks and more:

*Note:* Items marked with `WIP:` are still being worked on and are maybe not fully complete.

1.  Initializing new databases
2.  WIP: Creating new users
3.  WIP: Content moderation (Deleting users, posts and banning instances)
4.  WIP: Starting, stopping and restarting the pothole server program
5.  WIP: Checking and validating the configuration file.

# The purely philosophical and unpractical.

This section contains questions that regular users will likely not need
but that might answer questions related to Pothole\'s philosophy and
uniqueness.

For more information about the design choices of Pothole and the
rationale for them, check out this [webpage](file:///design/)

## What does X mean?{#definitions}

Pothole's website and documentation uses a lot of advanced technical words that are a bit confusing and not immediately apparent.
To help you understand our website to the fullest! We have provided a table of words that we commonly use, their definitions and commonly-used words to avoid.

Word | Definition | Commonly-used misnomers
---|---|---|
Misnomer | A name that is wrong or incorrect | (None)
Server daemon | This means the actual server program that you run in order to create an instance. | (None)
Instance | An instance is a website, server or whatever that runs an independent server of its own. This server might run Mastodon, Pothole or some other software. | Mastodon server
ActivityPub | A protocol that allows different websites to exchange messages with each other. Think of this like Email but better. | Mastodon protocol
Fediverse | A portmanteau of the words "Federated" and "Universe", it's basically a network of computers that all can talk to each other using different protocols (ActivityPub is one of these protocols) | Mastodon network
Protocol | A set of rules and such that dictate something of value. | (None)

You might have noticed that a lot of the misnomers are related to the [mastodon](https://joinmastodon.org/) server program. 
This is because ever since Elon Musk bought Twitter, people have been using the word "Mastodon" to describe the Fediverse.
But it is the wrong word to use when describing these things,
there's a diverse ecosystem of software that's used in the Fediverse, and calling it all "Mastodon" gives credit to the wrong people.

## Is Pothole a microblogging server or a social-media server?

These terms are interchangable in most cases,
but the documentation does clarify Pothole as a microblogging server
and Pothole is designed with that idea in mind,
I essentially want Pothole to be a self-hostable, federated version of Tumblr.

## Why is pothole licensed under the AGPLv3?

This is more of a strategic licensing move.
I don't want to try to "be fair to proprietary software developers",
moreover, [proprietary software should not exist](https://www.gnu.org/philosophy/free-digital-society.en.html) at all.

I do **not** want my work to be used to oppress the essential freedoms of others so I will license pothole strategically to prevent that.

You have the following choices when it comes to legally complying with pothole's licensing (Ranked from most ethical to least ethical):

1.  Accept that sharing is caring and release the source code.
2.  Simply don't use libpothole.
3.  Negotiate a licensing deal with me, the lead developer.

Lots of people claim that the GPL is an "anticapitalist" license but actually, it's perfect.
Either I get code contributions (from your GPL compliance) or I get money (from you negotiating a licensing deal) or you spend money creating something similar.

Yes, the GPL is confusing but what's even more confusing is the idea that permissive licensing provides more "real freedom".
Is the freedom to steal code and never share a good thing? I don't think so,
The GPL is better to ensure that software will always remain free.

Feel free to license software you don't care about permissive licenses
but I care about this project, so I will license it under the GPL (or some other copyleft license)

## How does Pothole differ from other ActivityPub backends?

Pothole does not try to do everything at once,
effort is made to write only readable and efficient code,
thus Pothole is not complex at all internally
which makes it a great option for users on resource-constrained systems such as Thinkpad homeservers or cheap VPSes.

Other servers simply include too many features that your users will never use or are written in languages that use too many resources
(or in some cases, [both](https://github.com/misskey-dev/misskey))
these don't just take up more size, memory or processing power
but they also can make the attack surface of the program larger
which, of course, makes the app insecure.

(Though, this is not a real problem you need to worry about.
Mastodon, Pleroma and Misskey are very secure.
This is just a technical argument in favor of Pothole)

Pothole in addition allows allows users to customize their profiles.
It inspires users to be creative with their profiles and to let their imagination run wild.
And the lack of a built-in frontend allows for greater flexibility!
*You* can choose what you want to use instead of having someone else choose for you.

## Why nim of all languages? Why not rust, go, assembly, or brainf\*\*\*?

Nim, in addition to being readable, fast and just plain awesome is:

1.  Memory-safe to some extent. See [this forum thread](https://forum.nim-lang.org/t/1961) and this [FAQ entry](https://nim-lang.org/faq.html#how-about-security-and-memory-safety)
2.  (Mostly) statically compiled which means we can simply drop a pre-compiled binary onto Raspberry Pis and have it work out-of-the-box. You *might* have to install sqlite and other run-time dependencies (But those are not large)
3.  Supported on lots of platforms and CPU architectures.
4.  Growing each day since more people are realizing how awesome it is

For these reasons, and others, Nim was chosen for this project.
Nim is such an underrated language,
I feel like if more people knew it then they would code more in it.
I have some criticisms when it comes to nimble
(It requires a GitHub account for publishing packages to the global directory.
Would it not be possible to add [git-send-email](https://git-scm.com/docs/git-send-email) as an additional option?)
but these are somewhat minor

If you look far enough in the git history logs for the Pothole server program,
you will see attempts at using Julia,
there are two problems with using Julia though.

1.  Julia cannot be statically compiled, which means you need to ship Julia along with the program (which is impractical and annoying) (There are some workarounds but I could never get them to work at all, so I am giving up) (Guile also suffers from this issue)
2.  I am pretty sure Julia is not meant for web apps, I could be wrong but it simply seems like its more for big data processing and statistics.

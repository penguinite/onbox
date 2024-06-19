---
title: "MRF"
description: "MRF allows you to manipulate and discard any kind of message. It's useful for basic administration tasks."
---

*Note:* This is an experimental feature, it is being worked on. 

Pothole's MRF feature is extremely similar to [Pleroma's MRF](https://docs-develop.pleroma.social/backend/configuration/mrf/), since it is basically the exact same feature.

The Message Rewriting Facility allows you to modify or reject messages. the "Message" in MRF is not limited to just posts, it includes Users and any kind of Activity as well. Which means that the possible use-cases for MRF is nearly unlimited.

Be very careful about the MRF policies that you choose to add, especially if they are custom-written and be sure to review them to make sure they are not doing something malicious in the background since real unrestricted code is being ran every time your server gets a new post, user or activity. In general, MRF policies should not import other modules (except for basic things such as standard library functions and `pothole/mrf` of course) and they absolutely, should **not** under any circumstances, be running database operations.

Here are a couple of possible use-cases:

1. [Making every post sound like an overexcited rambler](https://github.com/penguinite/pothole/blob/main/contrib/OVEREXCITED_RAMBLER_MRF.nim)
2. [Rejecting every user with the name "Alex"](https://github.com/penguinite/pothole/blob/main/contrib/alex_banhammer_mrf.nim)
3. Re-writing every post to include a picture of a dog.
4. Adding [Spongebob case](https://knowyourmeme.com/memes/mocking-spongebob) to every post.

And here are some actually useful, possible use-cases:

1. Blocking users from an annoying/harmful instance
2. Detecting follow-bots
3. Removing NSFW posts from the federated timeline
4. Scanning links in messages for phising, scams, fraud or anything else.
5. Removing attachments from instances deemed as harmful
6. Not sending private messages to instances that knowingly reveal them
7. Blocking instances that attach a common hashtag to all of their posts
8. Removing overly toxic messages

There are no limits to MRF beyond your imagination (and coding skills I suppose)
Anyway, since most instances are gonna want some common policies, Pothole has a couple of them built right into the program itself, any other MRF policy you want to add can be imported at run-time.

The `Simple` MRF policy is capable of handling most day-to-day administration. You can configure it to do the following:

* `allow`: if this feature is enabled then, Pothole will only accept messages from instances in this list and everyone else will be rejected.
* `reject`: Everything coming from instances in this list will be rejected. And nothing will ever be sent to instances on this list.
* `reject_post`: Every post coming from instances in this list will be rejected. Posts from your instances will be able to reach them however, Likes and boosts (and other activities) will not be rejected.
* `reject_activities`: Likes and boosts coming from the instances in this list will be rejected. Your posts will still be sent to these instances. This will also reject reports.
* `reject_reports`: Reports from the instances in this list will be rejected. But nothing else will be.
* `quarantine`: Posts coming from the instances in this list will not be shown in the federated timeline.
* `media_nsfw`: All media found in posts coming from the instances in this list will be marked as NSFW
* `media_removal`: All media found in posts coming from the instances in this list will be removed and not processed at all.
* `avatar_removal`: All avatars from users on the instances in this list will be removed.
* `header_removal`: All headers/banners from users on the instances in this list will be removed.

If you want to enable the `Simple` policy then you will have to add it in the MRF section of your config file, like so:

```toml
[mrf]

# Simply add "simple" to this list, like so.
active_builtin_policies={
    "simple"
}
```

Configuring the `Simple` policy can be done like this:

1. Find or write the `mrf.simple` section in the config file
2. Depending on the specific action you want to do, you will need to find the right config option.
3. Insert your instance and (optionally) a reason for blocking it. Here is an example:

```toml
[mrf.simple]

# Reject everything
reject=[
  "spam.world"
]
reject_reasons=[
  "Extreme amounts of spam"
]
```

(In that example, we are rejecting everything from spam.world and we are specifying "Extreme amounts of spam" as the reason why we are doing it)

`reject_reasons` can be an empty string.

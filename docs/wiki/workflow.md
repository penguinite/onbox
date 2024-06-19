---
title: "Development workflow"
description: "This page is about the development workflow we use, it also includes our release strategy and whatnot."
---

In the Pothole git repository, we have two special branches. `main` and `staging`.

* `main` is designed to hold the most production-quality and stable code we have. If someone were to clone `main` right this second, it should produce the best code we have available. (Which is typically the latest release)
* `staging` is where the actual development takes place. It does not matter if there is a bug or non-ideal code here because the whole point is to simply add features, bugfixes, potential optimizations and anything else we have for the next release.

## Release strategy

Every two months or so, a feature-freeze in the `staging` branch kicks in.
This is a short period in which no new features are accepted.
And any incomplete features are thrown out or finished quickly.

Then, the codebase as a whole gets tested for any bugs.
If any are found then they must be fixed before the release.
This whole period lasts only for about a week or two so as to give time to the developers to fix and test everything quickly.

Finally, `staging` gets merged with `main` and a new `staging` branch gets created from `main`
and shortly afterwards, a new release gets a new git tag and announced to the world via the Fediverse, Email, Pigeon messenger and whatever else we have.

But this release strategy and workflow only applies to regular features, bug fixes and anything else a developer would normally write. If a security issue has been found then it is directly submitted and announced as a security release, security takes precedence over routine.

## Feature branch model

All pothole projects follow the [Feature branch workflow](https://www.atlassian.com/git/tutorials/comparing-workflows/feature-branch-workflow),
which basically means creating new branches for new features and merging them into the `staging` branch.

Patches that are bug-free or that need only a couple of fixes can be submitted directly to the `staging` branch.

You generally only need to create a new branch for a new feature if what you are working on is heavy
and complex (ie. postgres database, federation, JSON parsing etc.)

## Mailing lists

Tilambda, the hosting provider, mainly uses a mailing list system for project discussion.
So we use email lists to communicate and plan things in Pothole.

The following lists exist (or will exist in the future):

*   pothole: For suggestions, feedbacks and bug reports in all pothole projects.
*   pothole-announcements: A relatively low-volume list for new minor or major updates.
    Security updates are also announced here.
*   pothole-dev: For discussing new features and sending patches in pothole and potholectl.

Those lists are the essential lists where serious development talk happens.
But if you are looking for more casual communication
(Advice when setting up new servers, non-critical issues or other)
then you will appreciate the pothole-chat list which is basically just that.

pothole-chat is slightly less strict than the `pothole` list,
you can do the following things there:

*   Announce interesting news about Pothole (Links to your own posts are also welcome here)
    (*Please don't announce new versions here, we already have a list for that*)
*   Discuss design choices and simply chat about Pothole.
*   Announcing new instances, or any interesting Fediverse news in general.
*   Planning revolutions and coups of governments worldwide. (For legal reasons, this is a joke)

### Adding/Discussing new features

First of all, if the idea has gained traction in the regular pothole mailing list
then it might get a new branch and an email thread on the development mailing list.
In which case, the feature is worked on as usual and discussion about the feature happens in its respective thread.

### Submitting patches

Just send an email to the libpothole-dev list or pothole-dev list and wait for someone to review your patch.
If it looks good then it will be patched immediately.

You can send patches via [git-send-email](https://git-send-email.io/) or [git format-patch](https://davidwalsh.name/git-export-patch) (Attaching a `.patch` file to your regular email submission) both are fine.

If your patch contains some basic formatting issues then we will ask you for an extra patch to fix these issues.
Either way, the end-result is a patch that is directly applied to the `staging` branch.

When your patch gets pushed into `staging`, you will have earned the role of *"Pothole contributor"*.
Feel free to brag about this into your email signature, social-media bio, CV or auto-biography book.

We do require that all commits are signed off by the actual author, just add the `-s` flag into the git command and that should take care of it. (Oh and be sure to add your name and email into the copyright disclaimer)

## Code style

We go by the regular Nim coding styles, we use two spaces for indentation and we use no parenthesis for `log` and `error`
But honestly, you can submit your code however just as long as its somewhat readable. If it's something minor then I will edit the patch myself.

### Submitting bug reports

Just send an email to the regular pothole list with a description of the issue,
along with any and all output from Pothole and some basic info such as your version, the branch you built from and the platform you are using.

## What happens to merged feature branches.

Feature branches that are already merged into `main` or `staging` will likely be deleted immediately.
So don't depend on a feature-branch in your scripts unless you are ready to fix any issues that occur.
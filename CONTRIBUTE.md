# How to contribute to pothole

TODO: Migrate information from the site over here

Despite what it looks like, pothole isn't *just* one project. It's more like three different projects stored in a single repository.
Why store it all in one? Well for one, it makes it easy to contribute, instead of having to coordinate a change in 3 different repositories, we only have to coordinate it in a single one.

Here is a list of the different "projects" going on in this repository

## Pothole

This is what you would run on a server to turn it into a social media site. The source for it is stored in `pothole.nim` and any extra modules are stored in the `pothole/` folder.

## Potholectl

Potholectl is a program designed to make maintaining Pothole servers easy and efficient. The source for it is stored in `potholectl.nim` and any extra modules (for extra functionalities, subsystems and help prompts) are stored in the `potholectl/` folder.

## Quark

Quark is, at its most basic level, a framework for storing, retrieving and processing Users, Posts and Activities. Unlike the other two projects, it's not a binary, it's a library and so the source code for it is stored in the `quark/` folder.

In general, we try to make Quark as independent as possible. Since the split, nearly all Pothole-specific functionality has been moved into pothole or potholectl. This does mean you can use Quark to build your own social media server if you'd like, but the documentation for Quark is practically non-existent. This is something I hope to address in the future.
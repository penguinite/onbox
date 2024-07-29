# How to contribute to pothole

TODO: Migrate information from the site over here

## Subprojects

Despite what it looks like, pothole isn't *just* one project. It's more like three different projects stored in a single repository.
Why store it all in one? Well for one, it makes it easy to contribute, instead of having to coordinate a change in 3 different repositories, we only have to coordinate it in a single one.

In the future though, it might be worth it to split this into three different repositories.

Here is a list of the different "projects" going on in this repository

### Pothole

This is what you would run on a server to turn it into a social media site. The source for it is stored in `pothole.nim` and any extra modules are stored in the `pothole/` folder.

### Potholectl

Potholectl is a program designed to make maintaining Pothole servers easy and efficient. The source for it is stored in `potholectl.nim` and any extra modules (for extra functionalities, subsystems and help prompts) are stored in the `potholectl/` folder.

### Quark

Quark is, at its most basic level, a framework for storing, retrieving and processing Users, Posts and Activities. Unlike the other two projects, it's not a binary, it's a library and so the source code for it is stored in the `quark/` folder.

In general, we try to make Quark as independent as possible. Since the split, nearly all Pothole-specific functionality has been moved into pothole or potholectl. This does mean you can use Quark to build your own social media server if you'd like, but the documentation for Quark is practically non-existent. This is something I hope to address in the future.

In its current state, Quark incorporates **a lot** of Pothole-specific features such as apps, oauth tokens, session and so on. In the future, Quark will be re-written to *only* contain processing code for Users, Activities and Posts. I just need to figure out a way to extend the database layer on another project without a lot of complexity. (And I also need to read through Quark's code as it has accumulated a lot of strange and confusing stuff.

## Style guide

Summary:
1. There is no propely-enforced styling guide.
2. Please separate imports.

What we would like to do in the future:
1. Follow [NEP-1](https://nim-lang.org/docs/nep1.html) (The Nim standard library style guide.)
2. Feel free to send patches enforcing these rules.
3. Separate imports properly.

Import statements should always be at the top,

The first import statements should be from the subproject itself, fx. if you're writing a module/fix/patch in Pothole then modules from Pothole itself should be at the top of the import list, you can then choose for yourself whether Quark or Potholectl should follow next. Either way, after all 3 are sorted, you can start adding the standard library

So, again, summarized, the import list order is this:
1. Imports from this subproject
2. Imports from other subprojects (separated of course) (Quark -> Pothole -> Potholectl)
3. Imports from the standard library
4. Imports from nimble/elsewhere

Here is a demonstration, let's say this file is a part of Potholectl.

```nim
# Somewhere from Potholectl
import potholectl/shared

# Somewhere from Pothole
import pothole/[conf, lib]

# Somewhere from Quark
import quark/[user, post, strextra]

# Somewhere from the standard library
import std/strutils except isEmptyOrWhitespace, parseBool

# Elsewhere
import rng
```

Imports should always be absolute, unless you can't get absolute imports to work properly, in which case, relative imports are acceptable. `import quark/user` is good but `import ../quark/user` is bad.

HTML Files should be formatted with Tidy, using the following command: `tidy -i -m -w 160 -ashtml -utf8 html_file_here`
You can find Tidy in most distribution repositories, and I don't think it matters what version you choose really.

## How to make changes (and where to)

### Wanna fix an API route? (/api/v1/..., /api/pleroma/...)

All API code for Pothole is stored in the `pothole/api/` folder, here you will find a bunch of files, each file contains the routes for a specific method. (`apps.nim` handles `/api/v1/apps/` and so on)

If you're still in doubt about where an API method is then you can always check `pothole/api.nim`, (Ctrl + Left-click on VSCode/VSCodium is helpful here to find the origin of the function, but it's not necessary)

### Creating a new API route.

First of all, if its a new method then create a new module for it in `pothole/api/` and then edit `pothole/api.nim` with the following changes:

1. Import your new module: `import pothole/api/MODULE`
2. You should be able to see a big variable named apiRoutes.
3. Add a new entry to it with the following format: `("/full/route/here", "HTTP_METHOD_HERE_ALL_CAPS", routeHandlerHere),`
4. Boom! You should be done now!

If it's just a new route in an existing method then you can follow the above routine, without creating a new module in `pothole/api/`.

### Creating a new potholectl command.

In the past, potholectl used a confusing blend of case statements, string tables containing documentation and std/parseopt. But now, it uses cligen.

So, if you know how to use cligen, you know how to add a new command.

If you don't know how to use cligen, then just write your command as a normal function, where the arguments are command-line parameters that you can pass, and then adjust potholectl to add the new command.


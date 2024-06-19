---
title: "Compiling pothole from scratch for Linux systems"
---

This tutorial covers only basic compilation for Pothole.
The instructions here can be used to compile code in the `main` branch and the `staging` branch.

For this tutorial, you will need:

* Nim: Which you can download from the [main webpage](https://nim-lang.org/) or from your package manager.
* git: You can get this from your package manager.
* Your favorite C compiler (gcc is recommended) 
* Some basic shell knowledge.

This tutorial assumes you are using a Linux machine
(real Linux, not WSL. You can do this in a VM or live CD if you really need Windows.)

## Clone the pothole repository

To get started, you need to clone the pothole repository. And here, you
will have to make a choice between the `main` branch and the `staging`
branch.

### What is main?

`main` is where the latest development on Pothole happens.
It contains all the brand new shiny features for you to play with.
The problem is that stability is not a priority and so because of that,
some bugs might not be fixed and some features might not be completely finished.
And also this branch changes every day, there is no solid versioning here
and you might find it hard to keep your server up-to-date.

### What is stable?

`stable` is a branch that contains production-ready, tested and complete code.
We generally try to keep code here as stable as possible,
which means it's great for servers and other production environment.
We highly recommend you use this for your build unless you like living dangerously.

Now that you have chosen what branch you will clone,
run the following command (Make sure you have git installed)

`git clone https://github.com/penguinite/pothole.git -b YOUR_BRANCH`

Obviously replace `YOUR-BRANCH` with either `main` or `stable`

After the command has finished running, you should be able to see a folder named `pothole`.
You should switch to it as it contains the source code.

## Building pothole.{#building}

Now it's time to actually build pothole.
Make sure you have nim and nimble installed for this part.

Open up a shell, and type `nimble -d:release build`, feel free to insert any [build options](/pothole/build-options/) you want before the "build" part. When you are ready to build pothole, run the command.

The command should, automatically, download any required dependencies and build a stable version of pothole (assuming you have selected the `stable` branch and not the `main` branch)

When the command has finished running, you should be able to see a `build/` folder.
This contains your build of pothole along with [potholectl](/pothole/potholectl/) and a sample [configuration file](/pothole/config-file/)

TODO: Cover some basic configuration options
TODO: Cover reverse proxying and a basic media proxy
TODO: systemd + OpenRC service initialization
TODO: Creating an admin user with potholectl
TODO: Link to any relevant tutorials (how to use Pothole, how to install a frontend and so on)
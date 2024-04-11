# Quick setup guide

This is a quick easy-to-follow guide for setting Pothole on any modern Linux distribution.

Requirements:

1. Any modern-ish Linux-based distribution: I have written and tested this tutorial with Pop OS but any modern Linux distribution should work as long as the rest of the dependencies are installed and working.
2. Nim version higher than 2.0.2: Nim is the main programming language used to write Pothole in, you can find information on where to download Nim in the [Nim website](https://nim-lang.org)
3. Git access: Git will be used to download the pothole source code, you can alternatively skip git and just download a zip file from GitHub containing the source code.
4. Docker or postgres database access: Postgres is the database used by pothole, you might be able to download the postgres server from your distribution, or alternatively you can have Docker installed and let `potholectl` install a database container for you.

## Fetch Pothole's source code

*If you already have a copy of the Pothole source code then feel free to skip this step*

Open up a shell and run the command `git clone https://github.com/penguinite/pothole/` to download a copy of the Pothole source code.
When git finishes downloaded the source code, switch to the new folder by running `cd pothole/`

## Building Pothole

To build pothole with production settings (In most cases, this is what you would want), Run the command `nimble -d:release build`
You will then see a folder

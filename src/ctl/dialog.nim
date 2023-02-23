import help

proc helpPrompt() =
  ## A program that writes the entirety of the help prompt.
  for x in helpDialog:
    echo(x)
  lib.exit()

proc versionPrompt() =
  echo "Potholectl " & lib.version
  echo "Copyright (c) Leo Gavilieau 2023"
  echo "Licensed under the GNU Affero GPL License under version 3 or later."
  lib.exit()
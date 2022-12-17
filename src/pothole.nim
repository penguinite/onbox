# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.

import conf
import env
import strutils

echo("Pothole")
echo("Copyright © Leo Gavilieau 2022.")
echo("Licensed under the GNU Affero General Public License version 3 or later")


echo("Using config file: ", env.fetchConfig())

# Setup conf.nim to parse the configuration file
conf.setup(env.fetchConfig())


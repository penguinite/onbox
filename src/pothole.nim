# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.

import conf
import env
import lib

echo("Pothole version ", lib.ver)
echo("Copyright © Pothole Project 2022.")
echo("Licensed under the GNU Affero General Public License version 3 or later")
echo("Using config file: ", env.fetchConfig())

# Setup conf.nim to parse the configuration file
conf.setup(env.fetchConfig())

if conf.exists("instancename"):
    echo("Instance name: ", getString("instancename"))

if conf.exists("instancedesc"):
    echo("Instance description: ", getString("instancedesc"))

if conf.exists("instancerules"):
    echo("Instance rules:")
    var i: int = 0
    for x in getArray("instancerules"):
        inc(i)
        echo($i & ". " & $x)


# And we all *shut* down...
# Copyright © Louie Quartz 2022
# Licensed under the AGPL version 3 or later.
#
## A module for fetching resources
import conf, os, tables

const resources*: Table[string,string] = {
  "index.html": staticRead("../static/index.html")
}.toTable()
# Copyright © penguinite 2024-2025 <penguinite@tuta.io>
# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This file is part of Onbox.
# 
# Onbox is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Onbox is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Onbox. If not, see <https://www.gnu.org/licenses/>. 
#
# conf.nim:
## This module stores the ConfigPool object (which is used heavily in the API layer)
## and it also stores some procedures related to configuration.
import std/os, iniplus

proc getConfigFilename*(c = "onbox.conf"): string =
  ## Returns the filename for the config file
  runnableExamples:
    ## onbox
    let config = parseFile(getConfigFilename())

    ## onboxctl
    proc example_command(config = "onbox.conf"): int =
      let conf = parseFile(getConfigFilename(config))
      return 0
  result = c
  if existsEnv("ONBOX_CONFIG"):
    result = getEnv("ONBOX_CONFIG")

## This is a config file pool.
## Mummy is a multi-threaded database server, and so using global variables is a bad idea.
## The configuration file is mutable even if we do not mutate it.
## So nim demands that we either store multiple copies (by using a pool) or
## we re-write our entire config system to be compile-tme instead of run-tme.
## 
## And we can't use let instead of var, because in Nim's eyes, let is still considered a GC-unsafe global.
## I don't know why let is considered GC-unsafe, it just is.
## (Maybe someone has to send a PR to re-classify it as a GC-safe global)
## 
## With let out of the way, pools are the only thing remaining.
## So we use waterpark and create a brand new "config file" pool.
## And we just use configPool.withConnection config:
## whenever we need access to the config file.
## 
## TODO: Figure out a way to trick nim into thinking config files are non-mutable or
## send a PR to reclassify let as a GC-safe non-mutable global. (As it should have been all these years)
## 
## Note: You can also use threadvars but those are fucking horrible, and pools are way easier to use.
## SERIOUSLY, I USED THREADVARS BEFORE, ITS THE EXACT SAME THING AS A POOL BUT 90% MORE ANNOYING TO USE.

import waterpark

type ConfigPool* = Pool[ConfigTable]

proc newConfigPool*(size: int, filename = getConfigFilename()): ConfigPool =
  ## Creates a new configuration pool.
  result = newPool[ConfigTable]()
  for _ in 0 ..< size:
    result.recycle(
      parseString(readFile(filename))
    )

template withConnection*(pool: ConfigPool, config, body) =
  ## Syntactic sugar for automagically borrowing and returning a config table from a pool.
  block:
    let config = pool.borrow()
    try:
      body
    finally:
      pool.recycle(config)
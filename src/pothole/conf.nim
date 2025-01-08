# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
#
# This file is part of Pothole.
# 
# Pothole is free software: you can redistribute it and/or modify it under the terms of
# the GNU Affero General Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
# 
# Pothole is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
# for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with Pothole. If not, see <https://www.gnu.org/licenses/>. 
#
# conf.nim:
## This module wraps configuration file parsers, it also has some essential functions
## Such as getConfigFilename()
## Currently, this module serves as a wrapper over the iniplus config parser.

# From standard library
import std/[os, tables]

# From elsewhere
{.define: iniplusCheckmaps.}
import iniplus
export iniplus

## TODO: Iniplus checkmaps could reduce this API's surface.
## And also make pothole way more performant (Less checks when retrieving config values)

# Required configuration file options to check for.
# Split by ":" and use the first item as a section and the other as a key

const required = {
  "db": {
    "password": @= CVString
  }.toTable,
  "instance": {
    "name": @= CVString,
    "summary": @= CVString,
    "description": @= CVString,
    "uri": @= CVString,
    "email": @= CVString
  }.toTable,
}

const optional = {
  "db": {
    "host": @= "127.0.0.1:5432",
    "name": @= "pothole",
    "user": @= "pothole"
  }.toTable,
  "instance": {
    "rules": @= @[""],
    "languages": @= @["en"],
    "disguised_uri": @= "",
    "federated": @= true,
    "remote_size_limit": @= 30
  }.toTable,
  "web": {
    "show_staff": @= true,
    "show_version": @= true,
    "port": @= 3500,
    "endpoint": @= "/",
    "signin_link": @= "/auth/sign_in/",
    "signup_link": @= "/auth/sign_up/",
    "logout_link": @= "/auth/logout/",
    "whitelist_mode": @= false
  }.toTable,
  "storage": {
    "type": @= "flat",
    "uploads_folder": @= "uploads/",
    "upload_uri": @= "",
    "upload_server": @= "",
    "default_avatar_location": @= "default_avatar.webp",
    "upload_size_limit": @= 30
  }.toTable,
  "user": {
    "registrations_open": @= true,
    "require_approval": @= false,
    "require_verification": @= false,
    "max_attachments": @= 8,
    "max_chars": @= 2000,
    "max_poll_options": @= 20,
    "max_featured_tags": @= 10,
    "max_pins": @= 20
  }.toTable,
  "email": {
    "enabled": @= false,
    "host": @= "",
    "port": @= 0,
    "form": @= "",
    "ssl": @= true,
    "user": @= "",
    "pass": @= ""
  }.toTable,
  "mrf": {
    "active_builtin_policies": @= @["noop"],
    "active_custom_policies": @= @[""]
  }.toTable
}

proc setup*(filename: string): ConfigTable =
  return parseString(readFile(filename), required, optional)

proc getConfigFilename*(): string =
  ## Returns the filename for the 
  result = "pothole.conf"
  if existsEnv("POTHOLE_CONFIG"):
    result = getEnv("POTHOLE_CONFIG")
  return result

proc getEnvOrDefault*(env: string, default: string): string =
  {.deprecated: "Deprecated to reduce Pothole's API, do not use.".}
  if not existsEnv(env):
    return default
  return getEnv(env)

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

proc newConfigPool*(size: int, filename: string = getConfigFilename()): ConfigPool =
  ## Creates a new configuration pool.
  result = newPool[ConfigTable]()
  for _ in 0 ..< size: result.recycle(setup(filename))

template withConnection*(pool: ConfigPool, config, body) =
  ## Syntactic sugar for automagically borrowing and returning a config table from a pool.
  block:
    let config = pool.borrow()
    try:
      body
    finally:
      pool.recycle(config)
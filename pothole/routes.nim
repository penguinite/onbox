# Copyright © Leo Gavilieau 2022-2023 <xmoo@privacyrequired.com>
# Copyright © penguinite 2024 <penguinite@tuta.io>
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

# From somewhere in Quark
#import quark/[user, post]

# From somewhere in Pothole
import conf, assets, database, routeutils

# From somewhere in the standard library
import std/[tables, mimetypes, os]

# From nimble/other sources
import mummy, waterpark/postgres

const renderURLs*: Table[string,string] = {
  "/": "index.html", 
  "/about": "about.html", "/about/more": "about.html", # About pages, they run off of the same template.
  "/auth/sign_in": "signin.html",
  "/auth/sign_up": "signup.html"
}.toTable

proc serveAndRender*(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "text/html"
  
  var path = req.path
  if path[high(path)] == '/' and path != "/":
    path = path[0..^2] # Remove last slash at the end of the path
  
  templatePool.withConnection obj:
    req.respond(
      200, headers,
      obj.render(renderURLs[path])
    )

proc serveStatic*(req: Request) =
  var headers: HttpHeaders

  let (dir, file, ext) = splitFile(req.path)
  discard dir # Fucking nim.
  templatePool.withConnection obj:
    headers["Content-Type"] = mimedb.getMimetype(ext)
    if ext == ".css":
      # Special case for CSS files.
      req.respond(200, headers, getAsset(obj.staticFolder, "style.css"))
    else:
      if not fileExists(obj.staticFolder & file & ext):
        headers["Content-Type"] = "text/html"
        req.respond(404, headers, renderError(obj.templatesFolder, "File couldn't be found."))
        return
      req.respond(200, headers, readFile(obj.staticFolder & file & ext))

  
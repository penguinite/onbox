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
# api.nim:
## This module just serves as a wrapper for all the modules in the api folder

# From somewhere in Pothole
import pothole/lib
import pothole/api/[instance, apps, oauth, nodeinfo, accounts]

# From somewhere else
import mummy

const apiRoutes* =  @[
  # (URLRoute, HttpMethod, RouteProcedure)
  ("/api/v1/instance", "GET", v1InstanceView),
  ("/api/v2/instance", "GET", v2InstanceView),
  ("/api/v1/instance/rules", "GET", v1InstanceRules),
  ("/api/v1/instance/extended_description", "GET", v1InstanceExtendedDescription),
  ("/api/v1/apps", "POST", v1Apps),
  ("/api/v1/apps/verify_credentials", "GET", v1AppsVerify),
  ("/oauth/authorize", "GET" , oauthAuthorizeGET),
  ("/oauth/authorize", "POST" , oauthAuthorizePOST),
  ("/oauth/token",  "POST", oauthToken),
  ("/oauth/revoke",  "POST", oauthRevoke),
  ("/api/v1/accounts/verify_credentials",  "GET", accountsVerifyCredentials),
  ("/api/v1/accounts/@id", "GET", accountsGet),
  ("/.well-known/nodeinfo", "GET", resolveNodeinfo),
  ("/nodeinfo/2.0", "GET", nodeInfo2x0),
]


proc logAPI*(req: Request) =
  ## This is tremendously slow, *only* use it for logging API routes.
  ## Do NOT use it ever in production.
  log "httpVersion: \"", req.httpVersion
  log "httpMethod: \"", req.httpMethod
  log "uri: \"", req.uri
  log "path: \"", req.path
  log "queryParams: \"", req.queryParams
  log "pathParams: \"", req.pathParams
  log "headers: \"", req.headers
  log "body: \"", req.body
  log "remoteAddress: \"", req.remoteAddress
  
  for route in apiRoutes:
    if req.path == route[0] and req.httpMethod == route[1]:
      route[2](req)
  
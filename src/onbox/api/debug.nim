when defined(debug):
  import mummy, std/json, ../shared
  proc oxDebug*(req: Request) =
    var headers: HttpHeaders
    headers["Content-Type"] = "application/json"
    req.respond(
      200,
      headers,
      $(
        %* {
          "version": shared.version,
          "mastoCompat": shared.mastoCompat,
          "sourceUrl": shared.sourceUrl
        }
      )
    )
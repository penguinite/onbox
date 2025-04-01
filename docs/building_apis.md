# Writing API procs in Pothole

This file provides a tutorial on how to create an API route in Pothole's codebase. It'll cover everything from validation to authentication and provide a template you can copy and adjust however you need.

The one unfortunate thing with Pothole's codebase is the heavy boilerplate associated with every API route, we might be able to fix this with metaprogramming magic but I have decided that it's important to keep the base of Pothole lightweight, which means fewer helper utilities and more boilerplate.

Start off by writing a Mummy request handler procedure, you can give it any name you'd like but usually we call the `Request` parameter for `req` as tradition.
```nim
proc x(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"
  req.respond(200, headers, "{\"test\": \"Hello World!\"}")
```

## Authentication

Sometimes you want an API route to only accept properly authenticated clients because you might be writing an API route that returns user data or an API route that is computationally expensive and so you'd want Pothole to limit access to it.

Proper authentication relies on the `Authentication` HTTP header, if a client does not supply it then there's no way we can verify who they are.
So the first step is usually to check for it with the `authHeaderExists()` from `pothole/routes`

```nim
proc x(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  # Our authHeaderExists check lies here
  if not req.authHeaderExists():
    req.respond(401, headers, "{\"error\": \"No authentication header\"}")
    # We have to place a return here, or else
    # Mummy (our web framework) will execute the rest of our code.
    # Which we do not want.
    return

  req.respond(200, headers, "{\"test\": \"Hello World!\"}")
```

but authHeaderExists() only checks for if a client has literally supplied an `Authentication` header, it does not check if that header is valid or if it corresponds to a token that is **in** the actual database. So the next thing we have to do is fetch the authentication token and verify that it exists in the database.

```nim
proc x(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  # Our authHeaderExists check lies here
  if not req.authHeaderExists():
    req.respond(401, headers, "{\"error\": \"No authentication header\"}")
    # We have to place a return here, or else
    # Mummy (our web framework) will execute the rest of our code.
    # Which we do not want.
    return

  # Here we fetch the authentication token from the client
  let token = req.getAuthHeader()

  # And then, we verify that it exists in the database.
  dbPool.withConnection db:
    # We will throw an error if the token does not exist
    if not db.tokenExists(token):
      req.respond(401, headers, "{\"error\": \"Authentication token supplied isn't valid!\"}")
      return

  req.respond(200, headers, "{\"test\": \"Hello World!\"}")
```

At this stage, Pothole will verify that a client has an actual token in the database, so now, it's somewhat protected.
But sometimes you wanna verify that the client caling this has *permission* to do something.

Some API routes require specific access levels in the form of *scopes*, for example, a client can specify that it wants the `read` scope at creation, which gives it access to read pretty much everything except for administrator settings but it can't do anything else, so it can't write new posts, follow others or like others posts.

Enforcing these sets of permissions is crucial for good security, a well-designed application will only use what it requires, and so if that token ever gets leaked then the potential damage of broad permissions will be minimized.

For this, we have `tokenHasScope()` from `pothole/db/oauth`, when given a token and a scope, it will check if that token has access to that scope in the database. Or, in layman's terms: it will check if the client has permission to do something.

Let's say our example API route needs the `read` scope, if  an application doesn't have that then too bad!

```nim
proc x(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  # Our authHeaderExists check lies here
  if not req.authHeaderExists():
    req.respond(401, headers, "{\"error\": \"No authentication header\"}")
    # We have to place a return here, or else
    # Mummy (our web framework) will execute the rest of our code.
    # Which we do not want.
    return

  # Here we fetch the authentication token from the client
  let token = req.getAuthHeader()

  # And then, we verify that it exists in the database.
  dbPool.withConnection db:
    # We will throw an error if the token does not exist
    if not db.tokenExists(token):
      req.respond(401, headers, "{\"error\": \"Authentication token supplied isn't valid!\"}")
      return
    
    # Our scope check is here!
    # We throw an error if the app doesn't have the `read` scope
    if not db.tokenHasScope(token, "read"):
      req.respond(401, headers, "{\"error\": \"No 'read' scope on token!\"}")
      return

  req.respond(200, headers, "{\"test\": \"Hello World!\"}")
```

API routes are sometimes personalized for each user, one obvious example is the [home timeline API route](https://docs.joinmastodon.org/methods/timelines/#home). Some applications are user-authenticated which means that a user had to login with their own username and password, and that user will be *connected* or *associated* with the application.

And of course! We have a way to get the user we need! `getTokenUser()` from `pothole/db/oauth` is exactly what we need in this case!
This procedure will return the ID of the user that the token has signed up with, if it is empty then it means that this token has *no user associated*

In our case, we will personalize the response of our API based on if there is a user associated or not. If your API requires user authentication then you have to throw an error when the string returned by `getTokenUser()` is empty.

```nim
proc x(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  # Our authHeaderExists check lies here
  if not req.authHeaderExists():
    req.respond(401, headers, "{\"error\": \"No authentication header\"}")
    # We have to place a return here, or else
    # Mummy (our web framework) will execute the rest of our code.
    # Which we do not want.
    return

  # Here we fetch the authentication token from the client
  let token = req.getAuthHeader()

  # The user ID we need will be stored here
  var user = ""

  # And then, we verify that it exists in the database.
  dbPool.withConnection db:
    # We will throw an error if the token does not exist
    if not db.tokenExists(token):
      req.respond(401, headers, "{\"error\": \"Authentication token supplied isn't valid!\"}")
      return
    
    # Our scope check is here!
    # We throw an error if the app doesn't have the `read` scope
    if not db.tokenHasScope(token, "read"):
      req.respond(401, headers, "{\"error\": \"No 'read' scope on token!\"}")
      return
    
    # Here we fetch the user associated with our token
    user = db.getTokenUser(token)    

  # Now we personalize the API response based on if there was a user
  # who accessed it or not.
  if user == "":
    # No user associated
    req.respond(200, headers, "{\"test\": \"Hello World!\"}")
  else:
    # With user association
    req.respond(200, headers, "{\"test\": \"Hello " & user & "!\"}")
```

### Lockdown Mode

By default, Pothole has some API routes that are open to any client, with no authentication required whatsoever. And some users dislike this, since it makes it easier to mine the data of any particular instance (along with its users) and it also makes it easier for potential DDOS attacks where clients continously call an expensive endpoint and bring down a server.

For this reason, we have a config setting which will lock down access to most open APIs when set to true, this option is called `lockdown_mode` (in the `web` section). If you're writing an open API route then it's expected that you also respect this configuration option, by requiring a valid token along with a valid appropriate scope.

We'll modify our previous example to be an open API and only require authentication when the lockdown configuration option has been set.
We will need to remove the user-personalization stuff however, because we can't have an open API and a personalized API at the same time.

```nim
proc x(req: Request) =
  var headers: HttpHeaders
  headers["Content-Type"] = "application/json"

  configPool.withConnection config:
    # Here we check if the instance has lockdown mode enabled.
    if config.getBoolOrDefault("web", "lockdown_mode", false):
      # Our authHeaderExists check lies here
      if not req.authHeaderExists():
        req.respond(401, headers, "{\"error\": \"No authentication header\"}")
        # We have to place a return here, or else
        # Mummy (our web framework) will execute the rest of our code.
        # Which we do not want.
        return

      # Here we fetch the authentication token from the client
      let token = req.getAuthHeader()

      # And then, we verify that it exists in the database.
      dbPool.withConnection db:
        # We will throw an error if the token does not exist
        if not db.tokenExists(token):
          req.respond(401, headers, "{\"error\": \"Authentication token supplied isn't valid!\"}")
          return

        # Our scope check is here!
        # We throw an error if the app doesn't have the `read` scope
        if not db.tokenHasScope(token, "read"):
          req.respond(401, headers, "{\"error\": \"No 'read' scope on token!\"}")
          return

  # Now we personalize the API response based on if there was a user
  # who accessed it or not.
  req.respond(200, headers, "{\"test\": \"Hello World!\"}")
```

## Client input

Many API routes have very simple inputs, or none at all. But some are complex because they need to parse 3 possible `Content-Type` values or they need to deal with legacy cruft or they need to deal ambigious documentation.

TODO: Finish this section.
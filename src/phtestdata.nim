import quark/[debug, db, posts, users, boosts, reactions]
import pothole/[lib, conf, database, routeutils]
import rng

let config = setup(getConfigFilename())

if not hasDbHost(config):
  log "Couldn't retrieve database host. Using \"127.0.0.1:5432\" as default"

if not hasDbName(config):
  log "Couldn't retrieve database name. Using \"pothole\" as default"

if not hasDbUser(config):
  log "Couldn't retrieve database user login. Using \"pothole\" as default"
  
if not hasDbPass(config):
  log "Couldn't find database user password from the config file or environment, did you configure pothole correctly?"
  error "Database user password couldn't be found."

log "Opening database at ", config.getDbHost()

# Initialize database
var deebee: DbConn
deebee = init(
  config.getDbName(),
  config.getDbUser(),
  config.getDbHost(),
  config.getDbPass()
)

log "Dropping everything already in db"
deebee.cleanDb()

log "Setting up database again"
try:
  deebee = setup(
    config.getDbName(),
    config.getDbUser(),
    config.getDbHost(),
    config.getDbPass()
  )
except CatchableError as err:
  error "Couldn't initalize the database: ", err.msg

log "Inserting fake users..."
for user in genFakeUsers():
  log "Inserting user with handle \"", user.handle, "\", whose display name is \"", user.name, "\""
  deebee.addUser(user)

log "Inserting fake posts...."
var postList = genFakePosts()
for post in postList:
  log "Inserting post by \"", post.sender, "\" with id \"", post.id, "\""
  deebee.addPost(post)

for reaction,users in genFakeReactions().pairs:
  for user in users:
    let post = sample(postList).id
    log "User \"", user, "\" reacted \"", reaction, "\" to post \"", post, "\""
    deebee.addReaction(post, user, reaction)

for level,users in genFakeBoosts():
  for user in users:
    let post = sample(postList).id
    log "User \"", user, "\" boosted with level \"", level, "\" to post \"", post, "\""
    deebee.addBoost(post, user, level)
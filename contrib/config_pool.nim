## Small "config pool" thing based on waterpark's fundamental "pool" object
## Read the TODO notice on pothole/routeutils.preRouteInit()
import waterpark
import pothole/[conf, lib]

type
  ConfigPool* = object
    pool: Pool[ConfigTable]

proc borrow*(pool: ConfigPool): ConfigTable {.inline, raises: [], gcsafe.} =
  pool.pool.borrow()

proc recycle*(pool: ConfigPool, conn: ConfigTable) {.inline, raises: [], gcsafe.} =
  pool.pool.recycle(conn)

proc newConfigPool*(size: int = 10, filename: string = getConfigFilename()): ConfigPool =
  result.pool = newPool[ConfigTable]()
  try:
    for _ in 0 ..< size:
      result.pool.recycle(setup(filename))
  except CatchableError as err:
    error "Couldn't initialize config pool: ", err.msg

template withConnection*(pool: ConfigPool, config, body) =
  block:
    let config = pool.borrow()
    try:
      body
    finally:
      pool.recycle(config)
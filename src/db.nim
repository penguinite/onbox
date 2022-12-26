# Copyright © Louie Quartz 2022
# Licensed under the AGPL version 3 or later.
#
# db.nim  ;;  Database functions

# From pothole
import lib
import conf
import data

# From standard library
import std/[db_sqlite,strutils]

{.gcsafe.}:
  var db*:DbConn;

# Initialize a database depending on its type.
proc init*(dbtype: string = get("database","type")) =
  var dbtype2 = toLower(dbtype)

  # Mostly for future-proofing
  case dbtype2:
  of "sqlite":
    # Here we try to open the database
    if exists("database","filename") == false:
      error("No database filename provided","db.init.sqlite")
    debug("Opening sqlite database at " & get("database","filename"),"db.init.sqlite")
    db = open(get("database","filename"),"","","")
  else:
    error("Unknown database type (" & dbtype & ")","db.init")

  # Initializes the globally shared database connection
  debug "Initializing database...","db.init"
  
  # Create users table
  if not db.tryExec(sql("CREATE TABLE IF NOT EXISTS users (id BLOB PRIMARY KEY,handle VARCHAR(65535) UNIQUE NOT NULL,name VARCHAR(65535) NOT NULL,local BOOLEAN NOT NULL, email VARCHAR(255),bio VARCHAR(65535),password VARCHAR(65535), salt VARCHAR(65535));")):
    # Database failed to initialize
    error("Couldn't initialize database! Creating users table failed!","db.init.actualinit")

  # Create posts table
  if not db.tryExec(sql("CREATE TABLE IF NOT EXISTS posts (id BLOB PRIMARY KEY,sender VARCHAR(65535) NOT NULL,written TIMESTAMP NOT NULL,updated TIMESTAMP,recipients VARCHAR(65535),post VARCHAR(65535) NOT NULL);")):
    error("Couldn't initialize database! Creating posts table failed!","db.init.actualinit")

  discard db.tryExec(sql("""INSERT INTO users (id, handle, name, local, email, bio, password) VALUES ("1", "kropotkin", "Peter Kropotkin", true, "peter.kropotkin@moscow.commune.i2p","I love to help others and I inspire people to help each other\nI thought I might explore this platform\nI don't know how it works!", "BetterBlackANDRed");"""))
  discard db.tryExec(sql("""INSERT INTO users (id, handle, name, local, email, bio, password) VALUES ("2", "lenin@communism.rocks", "Vladimir Lenin", false, "vladimir.lenin@cp.su", "Chairman of the Council of People's Commissars of the Soviet Union\n\nAny comments that are negative of the CCCP or CPSU will be reported.", "BetterRedThanDead");"""))
  discard db.tryExec(sql("""INSERT INTO users (id, handle, name, local, email, bio, password) VALUES ("3", "aynrand@google.google","Ayn Rand", false, "aynrand@aynrand.google.site","\nAuthor of The Fountainhead and Atlas Shrugged.\nSocial democrats, socialists, communists, anarchists or anyone who has morals:\nDo not interact or you will be reported to Google's Unsafe Persons Registry.","BetterDeadThanRed");"""))

# This actually takes a User object and puts it in the database
proc addUser*(user: User): bool =
  var newuser: User = escapeUser(user);
  debug("Inserting user " & $newuser, "db.addUser")
  if db.tryExec(sql"INSERT INTO users (id, handle, name, local, email, bio, password, salt) VALUES (?, ?, ?, ?, ?, ?, ?, ?,",newuser.id, newuser.handle, newuser.name, newuser.local, newuser.email, newuser.bio, newuser.password, newuser.salt):
    return true
  else:
    error "Failed to insert user " & $newuser, "db.addUser"

proc constructUserFromRow*(row: Row): User =
  var user: User;
  echo($row)
  user.id = row[0]
  user.handle = row[1]
  user.name = row[2]
  if row[3] == "1":
    user.local = true
  else:
    user.local = false
  user.email = row[4]
  user.bio = row[5]
  user.password = row[6]
  user.salt = row[7]
  return unescapeUser(user)

proc getUserById*(id: string): User =
  var row = db.getRow(sql"SELECT * FROM users WHERE id = ?", id)
  return constructUserFromRow(row)

proc getUserByHandle*(handle: string): User =
  var row = db.getRow(sql"SELECT * FROM users WHERE handle = ?", handle)
  return constructUserFromRow(row)

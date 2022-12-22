# Copyright © Pothole Project 2022
# Licensed under the AGPL version 3 or later.
# db.nim    ;;  Database operations.

import lib
import conf
import std/strutils
import db_sqlite

var dbcon*: DbConn = lib.db;
# This procedure is broken and I am not sure how to fix it
# db_sqlite has NO way of retrieving the output of any given SQL query
# It can only tell you if it ran successfully or not
proc existsTable*(table: string, dbtype: string = conf.getString("dbtype")): bool =
    if lib.db == nil:
        lib.err("lib.db isn't initialized, can't check if table " & $table & " exists.","db.existsTable")
    
    var execd: string;
    if dbtype == "sqlite":
        execd = "SELECT name FROM sqlite_master WHERE type='table' AND name='{" & table & "}';"


    return lib.db.tryExec(sql(execd))

proc setup*(dbtype: string = conf.getString("dbtype")): DbConn {.discardable.} =
    case toLower(dbtype):
    of "sqlite":
        if conf.exists("dbfilename"):
            lib.debug("Opening sqlite3 database at " & conf.getString("dbfilename"),"db.setup.sqlite")
            lib.db = db_sqlite.open(conf.getString("dbfilename"),"", "", "")
            doesDbExist = true
        else:
            lib.err("Missing dbfilename option","db.setup.sqlite")
    else:
        lib.err("Unrecognizable or unsupported database type " & dbtype, "db.setup")
    
    # Now we have a working connection to the database
    # So let's initialize it with our tables and stuff
    lib.debug("Creating users table...","db.setup")
    lib.db.exec(sql"""
        CREATE TABLE IF NOT EXISTS users (
        id BLOB PRIMARY KEY NOT NULL,
    	name VARCHAR(255) NOT NULL,
    	email VARCHAR(255),
    	handle VARCHAR(65535),
        password VARCHAR(65535),
        bio VARCHAR(65535)
    );""")
    lib.debug("Creating posts table...","db.setup")
    lib.db.exec(sql"""
    CREATE TABLE IF NOT EXISTS posts (
        id BLOB PRIMARY KEY,
        sender VARCHAR(65535),
    	written TIMESTAMP,
    	recipients VARCHAR(65535),
        post VARCHAR(65535)
    );
    """)

    return lib.db

# This functions expects a validated "User" object.
# It essentially converts our User to a database entry.
proc addUser*(user: User): bool {.discardable.} = 
    lib.debug("Adding " & $user & " to database","db.addUser")
    try:
        lib.db.exec(sql"INSERT OR REPLACE INTO `users` (`id`, `name`, `email`, `handle`, `password`, `bio`) VALUES (?, ?, ?, ?, ?, ?)", user.id, user.name, user.email, user.handle, user.password, user.bio)
    except:
        lib.err("Registering user failed with message " & $getCurrentExceptionMsg(), "db.addUser")
    return true

# Whereas the above function converted User to SQL, here we want to do the opposite.
proc getUser*(id: string = "", name: string = ""): User = 
    var handmadeMan: User;
    if isEmptyOrWhitespace(name) and isEmptyOrWhitespace(id):
        lib.warn("No name or id was provided","db.getUser")
        return handmadeMan
    
    if isEmptyOrWhitespace(name):
        # We use ID to search for user.
        discard
    else:
        # We use username to search for user.
        discard
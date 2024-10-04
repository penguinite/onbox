import quark/new/[strextra, shared]
import quark/private/database
import std/[tables, times]
import db_connector/db_postgres

const pollAnswersCols* = @[
  # The user who voted
  "uid TEXT NOT NULL",
  # The poll they voted on
  "poll_id TEXT NOT NULL",
  # The option they chose
  "option TEXT NOT NULL",

  # Some foreign keys for database integrity
  "foreign key (uid) references users(id)",
  "foreign key (poll_id) references polls(id)",
]

const pollCols* = @[
  # The ID for the poll
  "id TEXT NOT NULL PRIMARY KEY",
  # A comma-separated list of optioins/answers one can answer
  "options TEXT NOT NULL",
  # When the poll will no longer be open to votes
  "expiration_date TIMESTAMP",
  # Whether or not the poll is a multi-choice poll...
  "multi_choice BOOLEAN NOT NULL DEFAULT FALSE"
]

proc pollExists*(db: DbConn, poll_id: string): bool =
  ## Checks if a poll exists in the database.
  return has(db.getRow(sql"SELECT multi_choice FROM polls WHERE id = ?;", poll_id))

proc pollExpired*(db: DbConn, poll_id: string): bool =
  if not db.pollExists(poll_id):
    raise newException(DbError, "Poll with id \"" & poll_id & "\" doesn't exist.")

  # A one-liner that fetches the date from the db, and checks it against the current date.
  return toDateFromDb(db.getRow(sql"SELECT expiration_date FROM polls WHERE id = ?;", poll_id)[0]) <= now().utc()

proc getPoll*(db: DbConn, poll_id: string): (CountTable[string], int, bool, DateTime) =
  ## Retrieves a poll and all of its votes.
  ## 
  ## The part of the result contains the votes in a table. That table's key part corresponds to the "Poll option"
  ## while the value part contains the list of users who voted for that option.
  ## 
  ## So if jimmy votes for option A, then that table will look like ["A"] = @["jimmy"]
  ## 
  ## the other part is the total number of votes, and whether or not the poll is multi-choice and the last part is the expiration date for the poll.
  if not db.pollExists(poll_id):
    raise newException(DbError, "Poll with id \"" & poll_id & "\" doesn't exist.")

  let row = db.getRow(sql"SELECT expiration_date,multi_choice FROM polls WHERE id = ?;", poll_id)

  var
    votes: CountTable[string]
    votecount = 0

  for vote in db.getAllRows(sql"SELECT option FROM poll_answers WHERE poll_id = ?;", poll_id):
    inc votecount
    votes.inc(vote[1])

  return (
    votes, votecount, parseBool(row[1]), toDateFromDb(row[0])
  )

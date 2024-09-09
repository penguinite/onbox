import quark/new/[strextra, shared]
import quark/private/macros
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

proc getPoll*(db: DbConn, poll_id: string): (Table[string, seq[string]], int, DateTime) =
  ## Retrieves a poll and all of its votes.
  ## 
  ## The part of the result contains the votes in a table. That table's key part corresponds to the "Poll option"
  ## while the value part contains the list of users who voted for that option.
  ## 
  ## So if jimmy votes for option A, then that table will look like ["A"] = @["jimmy"]
  ## 
  ## the second part is the total number of votes, and the last part is the expiration date for the poll.

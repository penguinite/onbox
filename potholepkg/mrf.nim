import std/tables
import lib, conf, user, post, activity
export lib, conf, user, post, activity, tables

type
  postFilterProc* = proc (post: Post, config: Table[string, string]): Post {.nimcall.}
  userFilterProc* = proc (user: User, config: Table[string, string]): User {.nimcall.}
  activityFilterProc* = proc (user: Activity, config: Table[string, string]): Activity {.nimcall.}
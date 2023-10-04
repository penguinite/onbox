import std/tables
import lib, conf, user, post, activity
export lib, conf, user, post, activity, tables

type
  PostFilterProc* = proc (post: Post, config: Table[string, string]): Post {.nimcall.}
  UserFilterProc* = proc (user: User, config: Table[string, string]): User {.nimcall.}
  ActivityFilterProc* = proc (user: Activity, config: Table[string, string]): Activity {.nimcall.}
import std/tables
import lib, conf, user, post, activity
export lib, conf, user, post, activity, tables

type
  PostFilterProc* = proc (post: Post, config: Table[string, string]): Post {.cdecl, nimcall.}
  UserFilterProc* = proc (user: User, config: Table[string, string]): User {.cdecl, nimcall.}
  ActivityFilterProc* = proc (user: Activity, config: Table[string, string]): Activity {.cdecl, nimcall.}

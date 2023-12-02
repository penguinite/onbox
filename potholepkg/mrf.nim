import std/tables
import lib, conf, user, post, activity
export lib, conf, user, post, activity, tables

type
  PostFilterProc* = proc (post: Post, config: ConfigTable): Post {.cdecl, nimcall.}
  UserFilterProc* = proc (user: User, config: ConfigTable): User {.cdecl, nimcall.}
  ActivityFilterProc* = proc (user: Activity, config: ConfigTable): Activity {.cdecl, nimcall.}

import shared

proc processCmd*(cmd: string, args: seq[string] = @[]) =
  if checkArgs(args,"h","help"):
    helpPrompt("db",cmd)
import strutils

const list = @["Start = Post;","End = Post;","End"]

for x in list:
  echo($x.split("="))
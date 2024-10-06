import std/strutils

var s = "adqdqwdwdqwd@@@b"

echo s[0..s.find('@') - 1]
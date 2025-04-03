import onbox/assets, iniplus

# Flat storage with no upload_uri
var flatConfA = parseString("""
[instance]
uri = "https://cosmobousou.p"

[web]

endpoint = "/infinity/"

[storage]
type = flat
""")

# Flat storage with upload_uri set
var flatConfB = parseString("""
[instance]
uri = "https://cosmobousou.p"

[web]
endpoint = "/infinity/"

[storage]
type = flat
upload_uri = "https://media.cosmobousou.p/infinity/"
""")

assert flatConfA.getAvatar("shoushitsu") == "https://cosmobousou.p/infinity/media/user/shoushitsu/avatar.webp"
assert flatConfA.getHeader("gekishou") == "https://cosmobousou.p/infinity/media/user/gekishou/header.webp"
assert flatConfB.getAvatar("tomadoi") == "https://media.cosmobousou.p/infinity/user/tomadoi/avatar.webp"
assert flatConfB.getHeader("bunretsuhakai") == "https://media.cosmobousou.p/infinity/user/bunretsuhakai/header.webp"

try:
  discard parseString("[storage]\ntype=pony").getAvatar("shuuen")
  discard parseString("[storage]\ntype=pony").getHeader("infinity")
  assert true == false # War is peace.
except: discard
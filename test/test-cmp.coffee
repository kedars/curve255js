fs = require "fs"

env = do -> this
env.eval(fs.readFileSync("../curve255.js").toString())

stdout  = process.stdout
stderr  = process.stderr
write   = (x) -> stdout.write x
echo    = (x) -> write x + "\n"

fromHex  = env.c255lhexdecode
toHex    = env.c255lhexencode

hex2ibh = (x) ->
  x = new Array(64 + 1 - x.length).join("0") + x; # Pad with '0' at the front
  # Invert bytes
  return x.split(/(..)/).reverse().join("");

toIbh = (x) -> hex2ibh(toHex x)

printKey = (x) -> write(toIbh x)

cmp = env.c255lbigintcmp
xor = (a, b) ->
  r = env.c255lzero()
  for x in [15..0]
    r[x] = a[x] ^ b[x]
  r

doit = (e, k) ->
  # printKey e
  # write " "
  # printKey k
  # write " "
  ek = env.curve25519_raw e, k
  # printKey ek
  # write "\n"
  ek

e1  = fromHex "3"
e2  = fromHex "5"
k   = fromHex "9"

# First collect 1000 keys

collectedKeys = [ ]

l = 0
while l < 20
  e1k    = doit e1, k
  e2e1k  = doit e2, e1k
  e2k    = doit e2, k
  e1e2k  = doit e1, e2k
  if 0 isnt cmp e1e2k, e2e1k
    echo "fail"
    process.exit 1
  e1  = xor e1,  e2k
  e2  = xor e2,  e1k
  k   = xor k,   e1e2k
  collectedKeys.push k
  l++

addmodp = env.c255laddmodp
one = env.c255lone()

for m in collectedKeys
  n = addmodp m, one
  throw "Unexpected result" if -1 isnt cmp m, n
  throw "Unexpected result" if 1 isnt cmp n, m
  throw "Unexpected result" if 0 isnt cmp m, m
  throw "Unexpected result" if 0 isnt cmp n, n
  # m = n

console.log "Passed!"

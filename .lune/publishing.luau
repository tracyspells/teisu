local fs = require("@lune/fs")
local serde = require("@lune/serde")

local writeFile, readFile = fs.writeFile, fs.readFile
local encode, decode = serde.encode, serde.decode

print("Copying LICENSE file")
writeFile("dist/LICENSE", readFile("LICENSE"))

print("Copying Wally .toml file")
local wally_config = decode("toml", readFile("wally.toml")) 

writeFile("dist/wally.toml", encode("toml", wally_config))
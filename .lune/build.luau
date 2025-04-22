local fs = require("@lune/fs")
local serde = require("@lune/serde")
local rojo_project = require("templates/rojo")
local reset = require("utils/reset")
local run = require("utils/run")

local writeFile = fs.writeFile
local encode = serde.encode

reset("dist")

print("Generating sourcemap")
run("rojo", "sourcemap", "default.project.json", "-o", "sourcemap.json")

print("Processing library files")
run("darklua", "process", "lib", "dist/lib", "-c", ".darklua.json")

print("Writing Rojo project")
writeFile("dist/default.project.json", encode("json", rojo_project))

print("Creating Roblox model")
run("rojo", "build", "dist/default.project.json", "-o", "dist/teisu.rbxm")

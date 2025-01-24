local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local rojo_project = require("templates/rojo")
local reset = require("utils/reset")
local run = require("utils/run")
local path = require("utils/path")

local writeFile = fs.writeFile
local encode = serde.encode

local PATH_DIST = path(process.cwd, "dist")
local PATH_LIB = path(process.cwd, "lib")
local PATH_DARKLUA = path(process.cwd, ".darklua.json")
local ROJO_PROJECT = path(process.cwd, "default.project.json")
local ROJO_SOURCEMAP = path(process.cwd, "sourcemap.json")

reset(PATH_DIST)

print("Generating sourcemap")
run("rojo", "sourcemap", ROJO_PROJECT, "-o", ROJO_SOURCEMAP)

print("Processing library files")
run("darklua", "process", PATH_LIB, path(PATH_DIST, "lib"), "-c", PATH_DARKLUA)

print("Writing Rojo project")
writeFile(path(PATH_DIST, "default.project.json"), encode("json", rojo_project))

print("Creating Roblox model")
run("rojo", "build", path(PATH_DIST, "default.project.json"), "-o", path(PATH_DIST, `teisu.rbxm`))

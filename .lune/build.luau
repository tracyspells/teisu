local fs = require("@lune/fs")
local serde = require("@lune/serde")
local stdio = require("@lune/stdio")
local rojo_project = require("templates/rojo")
local wally_template = require("templates/wally")
local reset = require("utils/reset")
local run = require("utils/run")

local writeFile = fs.writeFile
local encode = serde.encode

local createModel = stdio.prompt("confirm", "Create .rbxm models?")
local createRelease = stdio.prompt("confirm", "Release to Wally/Pesde?")
local version = "0.0.0-dev"

if createRelease then
  local promptedVersion = stdio.prompt("text", "Semver version to publish as?")
  assert(
    promptedVersion:match("^(%d+)%.?(%d*)%.?(%d*)(.-)$") ~= nil,
    `{version} is not a valid semver version`
  )
  version = promptedVersion
end

reset("dist")

if createModel then
    print("Generating sourcemap")
    run("rojo", "sourcemap", "default.project.json", "-o", "sourcemap.json")
    
    print("Processing library files")
    run("darklua", "process", "lib", "dist/lib", "-c", ".darklua.json")
    
    print("Writing Rojo project")
    writeFile("dist/default.project.json", encode("json", rojo_project))
    
    print("Creating Roblox model")
    run("rojo", "build", "dist/default.project.json", "-o", "dist/teisu.rbxm")
elseif createRelease then
    local wally = table.clone(wally_template)
    wally.package.version = version
    -- TODO: publish to wally/pesde
end

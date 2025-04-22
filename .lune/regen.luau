local process = require("@lune/process")
local fs = require("@lune/fs")
local serde = require("@lune/serde")
local darkluaConfigTemplate = require("templates/darklua")
local luaurcConfigTemplate = require("templates/luaurc")
local path = require("utils/path")
local StringBuilder = require("utils/string-builder")

type ConvertRequire = {
	current: {
		name: "path",
		sources: { [string]: string },
	},
	rule: "convert_require",
	target: {
		indexing_style: "property",
		name: "roblox",
		rojo_sourcemap: "./sourcemap.json",
	},
}

type LuaurcConfig = {
	languageMode: ("strict" | "nonstrict"),
	lint: { [string]: boolean },
	globals: { string },
	aliases: { [string]: string },
}

local readDir, isDir = fs.readDir, fs.isDir
local readFile, writeFile, isFile = fs.readFile, fs.writeFile, fs.isFile
local encode, decode = serde.encode, serde.decode

local PATH_LIB = path(process.cwd, "lib")
local PATH_LUAURC = path(process.cwd, ".luaurc")

local ALIASES_KEYS_TO_EXCLUDE = {
	"testkit", "test-types", "lune", "mock", "teisu"
}

local function regen()
	local luaurc = decode("json", readFile(PATH_LUAURC)) :: LuaurcConfig

	local darkluaConfig = table.clone(darkluaConfigTemplate)
	local luaurcConfig = table.clone(luaurcConfigTemplate)

	local aliases = {}
	aliases["testkit"] = "test/testkit"
	aliases["test-types"] = "test/types"
	aliases["mock"] = "test/mock"
	aliases["lune"] = "~/.lune/.typedefs/0.8.9/"

	local stack: { { string } } = {}
	local function process_lib(files: { string }, p: string, directory: string)
		for _, dir in files do
			if isDir(path(p, dir)) then
				table.insert(stack, readDir(path(p, dir)))
				table.insert(stack, { p .. `/{dir}`, dir })
			elseif isFile(path(p, dir)) then
				local name = dir:gsub(".luau", "")
				local key: string, value: string = name, dir

				if dir == "init.luau" and directory ~= nil then
					key,value = directory, directory
				elseif dir == "init.luau" and directory == nil then
					key, value = `teisu`, nil :: never
				elseif dir ~= "init.luau" and directory ~= nil then
					value = `{directory}/{name}`
				elseif dir ~= "init.luau" and directory == nil then
					value = name
				end

				aliases[key] = path("lib", value)
			end
		end
	end

	local path_data = { PATH_LIB, nil :: never }
	local directories = readDir(PATH_LIB)
	repeat
		process_lib(directories, path_data[1], path_data[2])
		path_data = table.remove(stack) :: { string }
		directories = table.remove(stack) :: { string }
	until not directories

	luaurcConfig.aliases = aliases
	luaurcConfig.languageMode = "strict"

	if luaurc.globals ~= nil then
		for _, global in luaurc.globals do
			table.insert(luaurcConfig.globals, global)
		end
	end

	if luaurc.lint ~= nil then
		for key, value in luaurc.lint do
			luaurcConfig.lint[key] = value
		end
	end

	local darkluaSources = {}
	for key, value in next, aliases do
		if table.find(ALIASES_KEYS_TO_EXCLUDE, key) == nil then
			darkluaSources[`@{key}`] = value
		end
	end
	
	for _, rule in darkluaConfig.rules do
		if typeof(rule) == "table" and rule.rule == "convert_require" then
			local convertRequire = rule :: ConvertRequire
			convertRequire.current.sources = darkluaSources
		end
	end

	writeFile(
		path(process.cwd, ".luaurc"),
		StringBuilder()
			:appendLine(encode("json", luaurcConfig, true))
			:build()
	)

	writeFile(path(process.cwd, ".darklua.json"), encode("json", darkluaConfig, true))
end

regen()

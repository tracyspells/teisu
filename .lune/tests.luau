local fs = require("@lune/fs")
local process = require("@lune/process")
local testkit = require("@testkit/")
local test_types = require("@test-types/")
local path = require("utils/path")

type Map<K, V> = { [K]: V }

type CASE = test_types.CASE
type CHECK = test_types.CHECK
type TEST_FN = test_types.TEST_FN
type TESTS = test_types.TESTS

local readDir = fs.readDir
local isFile = fs.isFile

local kit = testkit.test()
local TEST, CASE, FINISH, SKIP = kit.TEST, kit.CASE, kit.FINISH, kit.SKIP
local CHECK, CHECK_EXPECT_ERROR = kit.CHECK, kit.CHECK_EXPECT_ERROR

local DIRECTORY = path(process.cwd, "test", "tests")

local function TITLE(name: string)
	print(`\n` .. testkit.color.white_underline(name) .. `\n`)
end

local tests: TESTS = {}

for _, entry in next, readDir(DIRECTORY) do
	local filePath = `{DIRECTORY}/{entry}`

	if not isFile(filePath) then
		continue
	end

	local testName = string.gsub(entry, ".luau", "")
	local test_fn = require(filePath) :: TEST_FN

	table.insert(tests, { name = testName, fn = test_fn })
end

table.sort(tests, function(a, b)
	return string.upper(a.name) < string.upper(b.name)
end)

for _, test in tests do
	TEST(test.name, function()
		test.fn(SKIP, CASE, CHECK, CHECK_EXPECT_ERROR)
	end)
end

TITLE("RESULTS:")

FINISH()

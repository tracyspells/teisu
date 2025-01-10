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

local TEST, CASE, CHECK, FINISH = testkit.test()

local DIRECTORY = path(process.cwd, "test", "tests")

local function TITLE(name: string)
    print(`\n` .. testkit.color.white_underline(name) .. `\n`)
end

local tests: TESTS = {} do
    for _, entry in next, readDir(DIRECTORY) do
        local filePath = `{DIRECTORY}/{entry}`
        local testName = string.gsub(entry, ".luau", "")

        if not isFile(filePath) then
            continue
        end
        
        table.insert(tests, { name = testName, fn = require(filePath) :: TEST_FN})
    end

    table.sort(tests, function(a, b)
        return string.upper(a.name) < string.upper(b.name)
    end)
end

TITLE "RESULTS:"

for _, test in tests do
    TEST(test.name, function() test.fn(CASE, CHECK) end)
end

FINISH()

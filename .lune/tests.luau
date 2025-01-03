local fs = require("@lune/fs")
local process = require("@lune/process")
local testkit = require("../test/testkit")
local path = require("utils/path")

type Map<K, V> = { [K]: V }

type CASE = (name: string) -> ()
type CHECK = <T>(value: T) -> T

type TEST_FN = (CASE, CHECK) -> ()

type TESTS = { {name: string, fn: TEST_FN } }

local readDir = fs.readDir
local isFile = fs.isFile

local TEST, CASE, CHECK, FINISH = testkit.test()

local DIRECTORY = path(process.cwd, "test", "tests")

local function TITLE(name: string)
    print()
    print(testkit.color.white_underline(name))
    print()
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

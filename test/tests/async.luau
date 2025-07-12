local task = require("@lune/task")
local teisu = require("../../lib/init")
local testkit = require("../testkit")
local types = require("../types")

local async = teisu.async
local effect = teisu.effect
local flec = teisu.flec
local cleanup = teisu.cleanup
local equals = testkit.seq

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
    do 
        CASE("yielding example #1")
        local result: string

        local value = async("hi", function()
            task.wait(0.1)
            return "bye"
        end)

        effect(function()
           result = value()
        end)

        CHECK(result == "hi")
        task.wait(0.3)
        CHECK(result == "bye")
    end
    
    do
        CASE("yielding example #2")

        local thread
        local value = async(0, function()
            thread = coroutine.running()
            coroutine.yield()

            return 1
        end)

        CHECK(value() == 0)
        coroutine.resume(thread)
        CHECK(value() == 1)
    end

    do
        CASE("rerun on flec change")
        local a = flec(1)
        local b = flec(2)

        local changes = 0
        local result = async(nil :: number?, function()
            a(); b()

            changes += 1
            return changes
        end)

        result()
        CHECK(changes == 1)
        a(2)
        result()
        CHECK(changes == 2)
        b(3)
        result()
        CHECK(changes == 3)
    end

    do
        CASE("cleanups")

        local a = flec(0)
        local did_run = false

        local value = async(nil :: number?, function()
            a()

            cleanup(function()
                did_run = true
            end)

            return 0
        end)

        value()
        CHECK(did_run  == false)
        a(1)
        value()
        CHECK(did_run == true)
    end

    do
        CASE("set function")

        local output: { string }?
        
        local value = async(nil :: { string }?, function(set)
            local result = {}

            for i = 1, 5 do
                task.wait(0.05)

                result = table.clone(result)
                table.insert(result, `hi{i}`)

                set(result)
            end

            return result
        end)

        effect(function()
            output = value()
        end)

        task.wait(0.3)
        CHECK(equals(output, { "hi1", "hi2", "hi3", "hi4", "hi5" }))
    end
end

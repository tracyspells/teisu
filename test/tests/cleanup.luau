local teisu = require("../../lib/init")
local types = require("../types")
local testkit = require("../testkit")

local cleanup = teisu.cleanup
local root = teisu.root
local equals = testkit.seq

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
    do
        CASE("runs immediately if outside root()")
        
        local cleaned_up = false
        cleanup(function()
            cleaned_up = true
        end)

        CHECK(cleaned_up == true)
    end

    do
        CASE("supports root()")

        local results = {} :: { string | boolean | number }
        local unroot = root(function()
            cleanup(function()
                table.insert(results, "hi")
            end)

            cleanup(function()
                table.insert(results, true)
            end)

            cleanup(function()
                table.insert(results, 5)
            end)
        end)

        CHECK(equals(results, {}))
        unroot()
        CHECK(equals(results, { 5, true, "hi" } :: { string | boolean | number }))
    end

    do
        CASE("cleans up objects")

        local ran = {}
        local unroot = root(function() 
            cleanup { disconnect = function() ran.disconnect = true end }
            cleanup { Disconnect = function() ran.Disconnect = true end }
            cleanup { destroy = function() ran.destroy = true end }
            cleanup { Destroy = function() ran.Destroy = true end } 
        end)

        CHECK(equals(ran, {}))
        unroot()
        CHECK(ran.disconnect)
        CHECK(ran.Disconnect)
        CHECK(ran.destroy)
        CHECK(ran.Destroy)
    end

    do 
        CASE("doesn't clean up same object twice")

        local cleanups = 0
        local object = { disconnect = function() cleanups += 1 end }

        local unroot = root(function()  
            cleanup(object)
            cleanup(object)
        end)

        CHECK(cleanups == 0)
        unroot()
        CHECK(cleanups == 1)
    end
end

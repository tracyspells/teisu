local teisu = require("../../lib/init")
local types = require("../types")

local context = teisu.context
local root = teisu.root
local effect = teisu.effect
local show = teisu.show

local do_nothing = function() return nil end

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
    do
        CASE("validate")

        local ctx = context()
        CHECK(type(ctx) == "table")
        CHECK(type(ctx.consume) == "function")
        CHECK(type(ctx.provide) == "function")
    end

    do
        CASE("can't be called outside of a scope")

        local ctx = context()

        CHECK_EXPECT_ERROR(function()
            ctx.consume()
        end)

        CHECK_EXPECT_ERROR(function()
            ctx.provide(1, do_nothing)
        end)
    end

    do
        CASE("get default context")

        local ctx = context(1)

        root(function() 
            CHECK(ctx.consume() == 1) 

            local v = ctx.provide(2, function()
                local current = ctx.consume()

                CHECK(current == 2)
                return current
            end)

            CHECK(v == 2)
            CHECK(ctx.consume() == 1)
        end)
    end

    do
        CASE("cascading contexts")

        local a = context(1)
        local b = context()

        local function component_three()
            effect(function()
                local result_a = a.consume()
                local result_b = b.consume()

                CHECK(result_a == 2)
                CHECK(result_b == true)
            end)

            CHECK(a.consume() == 2)

            return true
        end

        local function component_two()
            local c = show(true, function()
                return a.provide(2, component_three)
            end)

            CHECK(a.consume() == 1)
            return c
        end

        local function component_one()
            local result = a.consume()
            CHECK(result == 1)

            return b.provide(true, component_two)
        end

        root(function()  
            local result = component_one()
            CHECK(result() == true)
            CHECK(a.consume() == 1)
            CHECK(b.consume() == nil)
        end)
    end
end

local teisu = require("../../lib/init")
local types = require("../types")
local client = teisu.client
local flec = teisu.flec
local subscribe = teisu.subscribe

type SyncPayload = teisu.SyncPayload

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
    do
        CASE("syncs state payload")

        local a = flec(1)
        local client = client({ flecs = { a = a } })

        client:sync({
            type = "init",
            data = { a = 2 }
        })

        CHECK(a() == 2)
    end

    do
        CASE("syncs patches")

        local a = flec({ b = 1, c = 2 } :: { [string]: number? })
        local client = client({ flecs = { a = a } })

        client:sync({
            type = "init",
            data = { b = 1, c = 2  },
        })

        CHECK(a().b == 1)
        CHECK(a().c == 2) 

        client:sync({
            type = "patch",
            data = {
                {
                    op = "replace",
                    path = { "a", "c" },
                    value = 5,
                } :: any,

                {
                    op = "add",
                    path = { "a", "d" },
                    value = 2,
                } :: any,
            } :: any
        })

        CHECK(a().b == 1)
        CHECK(a().c == 5)
        CHECK(a().d == 2)
    end

    do
        CASE("batches patches")

        local a, b = flec(0), flec(0)
		local client = client({ flecs = { a = a, b = b } })
		local states = {}

        local unsubscribe_a = subscribe(a, function(new)
            states.a = new
        end)

        local unsubscribe_b = subscribe(b, function(new)
            states.b = new
        end)

        client:sync({
            type = "init",
            data = { a = a(), b = b() },
        })

        CHECK(a() == 0)
        CHECK(b() == 0)

        client:sync({
            type = "patch",
            data = {
                {
                    op = "replace",
                    path = { "a" },
                    value = 1,
                } :: any,

                {
                    op = "replace",
                    path = { "b" },
                    value = 2,
                } :: any,
            }
        })

        CHECK(a() == 1)
        CHECK(b() == 2)
        CHECK(states.a == 1)
        CHECK(states.b == 2)

        unsubscribe_a()
        unsubscribe_b()
    end
end

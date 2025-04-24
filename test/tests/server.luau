local teisu = require("../../lib/init")
local types = require("../types")
local testkit = require("../testkit")

type SyncPayload = teisu.SyncPayload

local server = teisu.server
local flec = teisu.flec
local step = teisu.step
local equals = testkit.deq

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
    local target: Player = {} :: any

    do
        CASE("sends state to new players")

        local a = flec(1)
        local server = server({ flecs = { a = a }, interval = -1 })
        local player: Player, payload: SyncPayload

		local disconnect = server:connect(function(...)
			player, payload = ...
		end)

        server:hydrate(target)
        step(0.1)

        CHECK(player == target)
        CHECK(payload.type == "init")
        CHECK(( payload.data :: { a: number } ).a == 1)

        disconnect()
    end

    do
        CASE("sends state patches")

        local a = flec({ b = 1, c = 2 } :: { [string]: number? })
        local server = server({ flecs = { a = a } })
        local _: Player, payload: SyncPayload

		local disconnect = server:connect(function(...)
			_, payload = ...
		end)

        server:hydrate(target)
        step(0.1)

        a({ b = 1, d = 2 })
        step(0.1)
        
        CHECK(payload.type == "patch")
        CHECK(equals(payload.data, {
            {
                op = "remove",
                path = { "a", "c" },
                value = { __none = "__none" },
            },
             
            {
                op = "add",
                path = { "a", "d"},
                value = 2 :: any,
            },
        }))

        a({ b = 1 })
        step(0.1)

        CHECK(payload.type == "patch")
        CHECK(equals(payload.data, {
            {
                op = "remove",
                path = { "a", "d" },
                value = { __none = "__none" },
            },
        }))

        disconnect()
    end
end

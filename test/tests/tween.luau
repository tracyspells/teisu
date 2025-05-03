local teisu = require("../../lib/init")
local tween_lib = require("../../lib/animation/tween")
local types = require("../types")
local mock = require("../mock")
local testkit = require("../testkit")
local collect = require("../utils/collect")

local flec = teisu.flec
local tween = tween_lib.tween
local is_tween = tween_lib.is_tween
local cleanup = teisu.cleanup
local root = teisu.root
local step = teisu.step
local effect = teisu.effect
local equals = testkit.seq
local Vector2 = mock.Vector2

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
	do
		CASE("validate")

		local test = tween(flec(0), { duration = 1 })

		CHECK(is_tween(test))
		CHECK(type(test.onComplete) == "function")
	end

	do
		CASE("unroot() support")
		local input, output = flec(0), nil
		local count = 0

		local unroot = root(function()
			output = tween(input, { duration = 1 })

            effect(function()
				output()
				count += 1
			end)
		end)

		CHECK(count == 1)

		unroot()

		CHECK(count == 1)

		input(2)

		CHECK(count == 1)
	end

	do
		CASE("cleanup() support")

		local test = tween(flec(0), { duration = 1 })

		CHECK(test() ~= nil)
		cleanup(test)
		CHECK(test() == nil)
	end

    do
		CASE("updates source (on next step)")

		local value = flec(10)
		local source = tween(value, { duration = 1, style = "Linear" })

		CHECK(source() == 10)
		value(20)
		CHECK(source() == 10)
		step(1 / 60)
		CHECK(source() ~= 10)
		CHECK(source() > 10)
	end

    do
		CASE("animates a value")

		local input = flec(0)
		local output = tween(input, { duration = 1 })

		local function run()
			for _ = 1, 20 do
				step(0.1)
			end
		end

		input(1)
		step(1 / 60)
		CHECK(output() ~= input()) -- check tween is moving
		run()
		-- the tween should be removed from the queue by now
		CHECK(output() == input()) -- check if it reached its destination

		local count = -1
        effect(function()
            output()
            count += 1
        end)

		step(1) -- attempt to cause another tween update
		CHECK(count == 0) -- check no update occurs as tween is finished

		collect() -- perform full gc
		input(2) -- tween should be re-added to tween queue
		step(0) -- process tween queue
		CHECK(count == 1) -- check tween was rescheduled correctly
	end

	do 
        CASE("does not support 'goal' type changes")

		local input = flec(0 :: number | Vector2)
		tween(input, { duration = 1 })

		CHECK_EXPECT_ERROR(function()
            input(Vector2.one)
		end)
	end

    do 
        CASE("delays briefly, then tweens to goal")

        local input = flec(0)
		local output = tween(input, { duration = 1, delay = 0.35 } )

        local expected =  { 
            0, 0, 0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7000000000000001,
            0.8, 0.89, 0.99, 1, 1, 1, 1, 1, 1, 1
        }

        local GOAL = 1

		local function run()
			local snapshot: { number } = {}

			for _ = 1, #expected do
				step(0.1)

                local value = output()
                value = if value < 1
                        then math.floor(value * 100) * 0.01
                        elseif value > 1 then math.ceil(value * 100) * 0.01
                        else value

				table.insert(snapshot, value)
			end

			return equals(snapshot, expected)
		end

        input(GOAL)
       
        local result = run()
        CHECK(result == true)
        CHECK(output() == GOAL)
    end

    do
        CASE("animate goal reversals")

        local input = flec(0)
		local output = tween(input, { duration = 0.8, reverses = true } )

        local expected = { 
            0.12, 0.25, 0.37, 0.5, 0.62, 
            0.74, 0.87, 0.99, 1, 
            0.87, 0.75, 0.62, 0.5, 0.37, 0.25, 0.12, 
            0, 0, 0, 0 
        }

        local function run(goal: number)
			local snapshot: { number } = {}

			input(goal)

			for _ = 1, #expected do
				step(0.1)

                local value = output()
                value = if value < 1
                        then math.floor(value * 100) * 0.01
                        elseif value > 1 then math.ceil(value * 100) * 0.01
                        else value


				table.insert(snapshot, value)
			end

			return equals(expected, snapshot)
		end

        local result = run(1)

        CHECK(result == true)
        CHECK(output() == 0)
    end

    do
        CASE("repeats tween once completed")

        local input = flec(0)
		local output = tween(input, { duration = 0.5, repeats = 3 } )

        local expected = { 
           0.2, 0.4, 0.6, 0.8, 1,
           0.2, 0.4, 0.6, 0.8, 1,
           0.2, 0.4, 0.6, 0.8, 1,
           0.2, 0.4, 0.6, 0.8, 1,
        }

        local function run(goal: number)
			local snapshot: { number } = {}

			input(goal)

			for _ = 1, 20 do
				step(0.1)

                local value = output()
                value = if value < 1
                        then math.floor(value * 100) * 0.01
                        elseif value > 1 then math.ceil(value * 100) * 0.01
                        else value


				table.insert(snapshot, value)
			end

			return equals(expected, snapshot)
		end

        local result = run(1)

        CHECK(result == true)
        CHECK(output() == 1)
    end
end

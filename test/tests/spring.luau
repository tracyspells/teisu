local teisu = require("../../lib/init")
local spring_lib = require("../../lib/animation/spring")
local types = require("../types")
local mock = require("../mock")
local testkit = require("../testkit")
local collect = require("../utils/collect")

local flec = teisu.flec
local spring = spring_lib.spring
local is_spring = spring_lib.is_spring
local cleanup = teisu.cleanup
local root = teisu.root
local step = teisu.step
local effect = teisu.effect
local equals = testkit.seq
local Vector2 = mock.Vector2

type CASE = types.CASE
type CHECK = types.CHECK

type Spring<T> = teisu.Spring<T>

return function(CASE: CASE, CHECK: CHECK)
	do
		CASE("validate")

		local test = spring(flec(0))

		CHECK(is_spring(test))
		CHECK(type(test.impulse) == "function")
		CHECK(type(test.setPosition) == "function")
		CHECK(type(test.setVelocity) == "function")
		CHECK(type(test.onComplete) == "function")
	end

	do
		CASE("unroot() support")
		local input, output = flec(0), nil
		local count = 0

		local unroot = root(function()
			output = spring(input, 30, 0.95)
		end)

		effect(function()
			output()
			count += 1
		end)

		CHECK(count == 1)
		unroot()
		CHECK(count == 1)

		input(2)
		CHECK(count == 1)
	end

	do
		CASE("cleanup() support")

		local test = spring(flec(0), 30, 0.95)

		CHECK(test() ~= nil)
		cleanup(test)
		CHECK(test() == nil)
	end

	do
		CASE("updates source (on next step)")

		local value = flec(10)
		local source = spring(value)

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
		local output = spring(input)

		local function run()
			for _ = 1, 20 do
				step(0.1)
			end
		end

		input(1)
		step(1 / 60)
		CHECK(output() ~= input()) -- check spring is moving
		run()
		-- the spring should be removed from the queue by now
		CHECK(output() == input()) -- check if it reached its destination

		local count = -1
        effect(function()
            output()
            count += 1
        end)

		step(1) -- attempt to cause another spring update
		CHECK(count == 0) -- check no update occurs as spring is finished

		collect() -- perform full gc
		input(2) -- spring should be re-added to spring queue
		step(0) -- process spring queue
		CHECK(count == 1) -- check spring was rescheduled correctly
	end

	do
		CASE("accepts damping ratio")

		local underdamped =  { 0.15,0.42,0.67,0.85,0.9500000000000001,1.01,1.03,1.03,1.02,1.02,1.01,1.01,1.01,0.99,0.99,0.99,0.99,0.99,0.99,1 }
		local critical =  { 0.14,0.37,0.5700000000000001,0.72,0.8200000000000001,0.89,0.93,0.9500000000000001,0.97,0.98,0.99,0.99,0.99,0.99,0.99,0.99,0.99,0.99,0.99,1 }
		local overdamped = { 0.13,0.32,0.48,0.61,0.71,0.78,0.8300000000000001,0.87,0.9,0.93,0.9400000000000001,0.96,0.97,0.97,0.98,0.98,0.99,0.99,0.99,0.99 }

		local GOAL = 1

		local function run(goal: number, damping: number, expected: { number })
			local snapshot: { number } = {}

			local input = flec(0)
			local output = spring(input, nil, damping)

			input(goal)

			for _ = 1, #expected do
				step(0.1)

				local value = output()
				value = if value < 1
					then math.floor(value * 100) * 0.01
					elseif value > 1 then math.ceil(value * 100) * 0.01
					else value

				table.insert(snapshot, value)

				if value == 1 then break end
			end

			return equals(snapshot, expected), output
		end

		local _, output = run(GOAL, 0.75, underdamped)
		CHECK(output() == GOAL)
		_, output = run(GOAL, 1, critical)
		CHECK(output() == GOAL)
		_, output = run(GOAL, 1.3, overdamped)
		CHECK(output() < GOAL) -- takes longer to settle
	end

	do
		CASE("supports 'goal' type changes")

		local input = flec(0)
		local output = spring(function()  return input() == 1 and Vector2.new(1, 1) or false end)

		local function run()
			for _ = 1, 20 do
				step(0.1)
			end
		end

		step(0.1)
		CHECK(output() == false)
		input(1)
		run()
		CHECK(output() == Vector2.new(1, 1))
	end
end

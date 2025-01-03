local teisu = require("../../lib/init")
local types = require("../types")

local flec = teisu.flec
local subscribe = teisu.subscribe

type CASE = types.CASE
type CHECK = types.CHECK

return function(CASE: CASE, CHECK: CHECK)
	do
		CASE("returns cleanup function")

		local test = flec(0)
		local unsubscribe = subscribe(test, function() end)

		CHECK(unsubscribe ~= nil)
		CHECK(type(unsubscribe) == "function")

		unsubscribe()
	end

	do
		CASE("self cleanup")

		local counter = flec(0)

		local disconnected = false
		local unsubscribe

		unsubscribe = subscribe(counter, function()
			if unsubscribe then
				CHECK(not disconnected)
				unsubscribe()
				disconnected = true
			end
		end)

		counter(2)
		counter(3)
	end

	do
		CASE("fired when state changes")

		local source = flec(0)

		local changes = 0

		local unsubscribe = subscribe(source, function()
			changes += 1
		end)

		CHECK(changes == 0)

		source(function(number)
			return number + 1
		end)

		CHECK(changes == 1)

		source(function(number)
			return number - 1
		end)

		CHECK(changes == 2)

		source(2)

		CHECK(changes == 3)
		unsubscribe()
	end

	do
		CASE("passes old and new state as arguments")

		local counter = flec(0)
		local initialState = counter()
		local newState, oldState

		local unsubscribe = subscribe(counter, function(new, old)
			newState, oldState = new, old
		end)

		counter(1)

		CHECK(oldState == initialState)
		CHECK(newState == counter())
		CHECK(newState ~= oldState)

		unsubscribe()
	end
end

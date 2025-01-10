local teisu = require("../../lib/init")
local types = require("../types")

local flec = teisu.flec

type CASE = types.CASE
type CHECK = types.CHECK

return function(CASE: CASE, CHECK: CHECK)
	do
		CASE("validate")

		local test = flec(0)

		CHECK(test ~= nil)
		CHECK(type(test) == "function")
	end

	do
		CASE("set and get")

		local source = flec(0)

		source(function(number)
			return number + 1
		end)

		CHECK(source() == 1)

		source(function(number)
			return number - 1
		end)

		CHECK(source() == 0)

		source(2)

		CHECK(source() == 2)
	end

	do
		CASE("custom equality function")

		local max = flec(0, function(old, new) return new < old end)

		max(5)
		CHECK(max() == 5)
		max(2)
		CHECK(max() == 5)
		max(10)
		CHECK(max() == 10)
	end
end

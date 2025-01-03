local teisu = require("../../lib/init")
local graph = require("../../lib/graph")
local count = require("../utils/count")
local types = require("../types")

local flec = teisu.flec
local peek = teisu.peek
local computed = teisu.computed

local castToNode = graph.castToReactable

type CASE = types.CASE
type CHECK = types.CHECK

return function(CASE: CASE, CHECK: CHECK)
	do
		CASE("doesnt register dependencies")

		local counter = flec(1)

		local multiplier = flec(2)
		local node = castToNode(multiplier)

		local double = computed(function()
			return counter() * peek(multiplier)
		end)

		CHECK(double() == 2)

		if node ~= nil then
			CHECK(count(node.parents) == 0)
			CHECK(count(node.children) == 0)
		end

		counter(2)

		CHECK(double() == 4)

		if node ~= nil then
			CHECK(count(node.parents) == 0)
			CHECK(count(node.children) == 0)
		end

		CHECK(peek(double) == 4)

		multiplier(4)
		counter(3)

		CHECK(double() == 12)

		if node ~= nil then
			CHECK(count(node.parents) == 0)
			CHECK(count(node.children) == 0)
		end

		CHECK(peek(double) == 12)
	end

	do
		CASE("returns non-molecules")

		CHECK(peek("hi") == "hi")
		CHECK(peek(1) == 1)
		CHECK(peek(false) == false)
		CHECK(peek(function() return 1 end) == 1)
	end
end

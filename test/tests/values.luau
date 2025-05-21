local teisu = require("../../lib/init")
local graph = require("../../lib/graph")
local teisu_types = require("../../lib/types")
local types = require("../types")
local testkit = require("../testkit")
local count = require("../utils/count")

local flec = teisu.flec
local observe = teisu.observe
local values = teisu.values
local peek = teisu.peek
local cleanup = teisu.cleanup
local castToNode = graph.castToReactable
local equals = testkit.seq

type Node<T> = teisu_types.Node<T>

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
	do
		CASE("validate")

		local items = flec({ "a", "b", "c" })
		local node = castToNode(items)
		local allUpperCase = values(items, function(item)
			return string.upper(item())
		end)
		
		local uppercase_result = allUpperCase()
		for index = 1, 3 do
			local uppercase = uppercase_result[index]
			local item = items()[index]

			CHECK(uppercase == string.upper(item))
		end

		items({ "d", "e", "f" })

		CHECK(equals(peek(allUpperCase), { "D", "E", "F" }))

		items(function(old) 
			local new = table.clone(old) 
			new[2] = nil 
			new[3] = nil
			return new 
		end)

		CHECK(equals(peek(allUpperCase), { "D" }))
		items({ "c", "d" })
		CHECK(equals(peek(allUpperCase), { "C", "D" }))

		items(function(old) 
			local new = table.clone(old) 
			new[2] = nil 
			return new 
		end)

		CHECK(allUpperCase()[2] == nil)
		items({})
		CHECK(count(allUpperCase()) == 0)

		CHECK(node ~= nil and count(node.children) == 1)
		cleanup(allUpperCase)
		CHECK(node ~= nil and count(node.children) == 0)
		node = nil
	end

	do
		CASE("observe() support")

		local added, deleted = 0, 0
		local cleaning_up = false

		local items = flec({ "a", "b", "c" })
		
		local map = values(items, function(item)
			return item()
		end)

		local stopObserving = observe(map, function(item, key)
			CHECK(item == items()[key])
			added += 1
			
			return function()
				if cleaning_up then return end

				CHECK(map()[key] == nil)
				deleted += 1
			end
		end)

		CHECK(added == 3)
		CHECK(deleted == 0)

		items({ items()[1], items()[3] })

		CHECK(added == 3)
		CHECK(deleted == 1)
		items({})
		CHECK(deleted == added)
		cleaning_up = true
		stopObserving()
	end

	do
		CASE("computes with constants")

		local data = {foo = "oof", bar = "rab"}
		local map = values(data, function(value)
			return value() :: any .. "baz"
		end)

		CHECK(typeof(map()) == "table")
		CHECK(map().foo == "oofbaz")
		CHECK(map().bar == "rabbaz")
		cleanup(map)
	end
end

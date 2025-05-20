local teisu = require("../../lib/init")
local graph = require("../../lib/graph")
local teisu_types = require("../../lib/types")
local types = require("../types")
local testkit = require("../testkit")
local count = require("../utils/count")

local flec = teisu.flec
local observe = teisu.observe
local values = teisu.values
local root = teisu.root
local new = teisu.new
local effect = teisu.effect
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
		CASE("root() support")

		local source = flec({ 1, 2, 3 })
		local node = castToNode(source)

		local unroot, output = root(function()
			return values(source, function(value)
				return value()
			end)
		end)

		output()
		CHECK(node ~= nil and count(node.children) == 1)
		unroot()
		CHECK(node ~= nil and count(node.children) == 0)
		node = nil
	end

	do
		CASE("ui support")

		local source = flec({ 1, 2, 3 })

		local function text_label(text: () -> number)
			return new "TextLabel" {
				Text = function() 
					return `{text()}` 
				end,
			}
		end

		local unroot, result = root(function()  
			local list
			local map = values(source, function(number)
				return text_label(number)
			end)

			effect(function()
				list = map()
			end)

			return list
		end)

		CHECK(result ~= nil)

		for index = 1, 3 do
			local entry: TextLabel? = result[index] :: any

			CHECK(entry ~= nil)
			CHECK((entry :: TextLabel).Text == `{index}`)
		end

		source(function(old)
			local new = table.clone(old)
			new[3] = nil

			return new
		end)

		for index = 1, 3 do
			local entry: TextLabel? = result[index] :: any

			if index == 3 then
				CHECK(entry == nil)
			else
				CHECK(entry ~= nil)
				CHECK((entry :: TextLabel).Text == `{index}`)
			end
		end

		unroot()
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

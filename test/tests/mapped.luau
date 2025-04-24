local teisu = require("../../lib/init")
local graph = require("../../lib/graph")
local teisu_types = require("../../lib/types")
local types = require("../types")
local testkit = require("../testkit")
local count = require("../utils/count")

local flec = teisu.flec
local observe = teisu.observe
local mapped = teisu.mapped
local root = teisu.root
local new = teisu.new
local effect = teisu.effect
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
		local allUpperCase = mapped(items, function(item)
			return string.upper(item)
		end)

		for index = 1, 3 do
			local uppercase = allUpperCase()[index]
			local item = items()[index]

			CHECK(uppercase == string.upper(item))
		end

		items({ "d", "e", "f" })

		CHECK(equals(allUpperCase(), { "D", "E", "F" }))

		items(function(old) 
			local new = table.clone(old) 
			new[2] = nil 
			new[3] = nil
			return new 
		end)

		CHECK(equals(allUpperCase(), { "D" }))
		items({ "c", "d" })
		CHECK(equals(allUpperCase(), { "C", "D" }))

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
		CASE("key extraction")

		local items = flec({ { key = 1 }, { key = 2 }, { key = 3 } })
		local map = mapped(items, function(item)
			return item, item.key
		end)

		for key = 1, 3 do
			local a, b = map()[key], items()[key]
			CHECK(a == b)
		end

		local previous = map()

		items(function(old)
			local new = table.clone(old)
			new[2] = new[3]
			new[3] = nil

			return new
		end)

		local new = map()
		local current = items()
		
		CHECK(new[1] == previous[1])
		CHECK(new[1] == current[1])
		CHECK(new[2] ~= previous[2]) -- checks if new[2] is nil
		CHECK(new[2] ~= current[2]) -- similar to above comment
		CHECK(new[3] == previous[3])
		CHECK(new[3] ~= current[3]) -- similar to first comment
	end

	do
		CASE("observe() support")

		local added, deleted = 0, 0
		local cleaning_up = false

		local items = flec({
			{ key = 1, value = "a" },
			{ key = 2, value = "b" },
			{ key = 3, value = "c" },
		})

		local map = mapped(items, function(item)
			return item, item.key
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

		items(function(old)
			local new = table.clone(old)
			new[2] = nil
			return new
		end)

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
			return mapped(source, function(...)
				return ...
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

		local function text_label(text: string)
			return new "TextLabel" {
				Text = text,
			}
		end

		local unroot, result = root(function()  
			local list
			local map = mapped(source, function(number)
				return text_label(`{number}`)
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

		for index = 1, 2 do
			local entry: TextLabel? = result[index] :: any

			CHECK(entry ~= nil)
			CHECK((entry :: TextLabel).Text == `{index}`)
		end

		unroot()
	end
end

local teisu = require("../../lib/init")
local types = require("../types")
local count = require("../utils/count")

local flec = teisu.flec
local observe = teisu.observe
local mapped = teisu.mapped
local subscribe = teisu.subscribe

type CASE = types.CASE
type CHECK = types.CHECK

return function(CASE: CASE, CHECK: CHECK)
	do
		CASE("validate")

		local updates = 0

		local items = flec({ "a", "b", "c" })
		local allUpperCase = mapped(items, function(item)
			return string.upper(item)
		end)

		local unsubscribe = subscribe(allUpperCase, function()
			updates += 1
		end)

		for index = 1, 3 do
			local uppercase = allUpperCase()[index]
			local item = items()[index]

			CHECK(uppercase == string.upper(item))
		end

		items({ "d", "e", "f" })

		CHECK(updates == 1)

		for index = 1, 3 do
			local item, uppercase = items()[index], allUpperCase()[index]
			CHECK(uppercase == string.upper(item))
		end

		items({ "c" })

		CHECK(updates == 2)
		CHECK(allUpperCase()[1] == string.upper(items()[1]))

		items({ "c", "d" })

		CHECK(updates == 3)

		for index = 1, 2 do
			local uppercase = allUpperCase()[index]
			local item = items()[index]

			CHECK(uppercase == string.upper(item))
		end

		items({ [1] = "b", [3] = "f" })

		CHECK(updates == 4)
		CHECK(allUpperCase()[2] == nil)

		items({})

		CHECK(updates == 5)
		CHECK(count(allUpperCase()) == 0)

		unsubscribe()
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
		CHECK(new[2] == previous[2])
		CHECK(new[2] ~= current[2])
		CHECK(new[3] == previous[3])
		CHECK(new[3] ~= current[3])
	end

	do
		CASE("observe() support")

		local added, deleted = 0, 0

		local items = flec({
			{ key = 1, value = "a" },
			{ key = 2, value = "b" },
			{ key = 3, value = "c" },
		})

		local map = mapped(items, function(item)
			return item, item.key
		end)

		local stopObserving = observe(map, function(item, key)
			local original = items()[key]
			CHECK(item == original)
			added += 1

			return function()
				local source = map()[key]

				CHECK(source == nil)
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

		CHECK(added == deleted)

		stopObserving()
	end
end

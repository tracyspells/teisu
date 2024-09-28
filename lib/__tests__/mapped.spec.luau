local types = require(script.Parent.Parent.types)
local utils = require(script.Parent.Parent.utils)
local mapped = require(script.Parent.Parent.mapped)
local flec = require(script.Parent.Parent.flec)
local observe = require(script.Parent.Parent.observe)
local subscribe = require(script.Parent.Parent.subscribe)

type Array<T> = types.Array<T>
type Map<K, V> = types.Map<K, V>

local count = utils.count

return function()
	it("returns mapped state", function()
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

			expect(uppercase).to.equal(string.upper(item))
		end

		items({ "d", "e", "f" })

		expect(updates).to.equal(1)

		for index = 1, 3 do
			local item, uppercase = items()[index], allUpperCase()[index]
			expect(uppercase).to.equal(string.upper(item))
		end

		items({ "c" })

		expect(updates).to.equal(2)
		expect(allUpperCase()[1]).to.equal(string.upper(items()[1]))

		items({ "c", "d" })

		expect(updates).to.equal(3)

		for index = 1, 2 do
			local uppercase = allUpperCase()[index]
			local item = items()[index]
			expect(uppercase).to.equal(string.upper(item))
		end

		items({ [1] = "b", [3] = "f" })

		expect(updates).to.equal(4)
		expect(allUpperCase()[2]).to.never.be.ok()

		items({})

		expect(updates).to.equal(5)
		expect(count(allUpperCase())).to.equal(0)

		unsubscribe()
	end)

	it("uses key extractor", function()
		local items = flec({ { key = 1 }, { key = 2 }, { key = 3 } })
		local map = mapped(items, function(item)
			return item, item.key
		end)

		for key = 1, 3 do
			local a = map()[key]
			local b = items()[key]
			expect(a).to.equal(b)
		end

		local previous = map()
		local previousItems = items()

		items({ previousItems[1], previousItems[3] })

		local result = map()
		local other = items()

		expect(result[1]).to.equal(previous[1])
		expect(result[1]).to.equal(other[1])
		expect(result[2]).to.never.be.ok()
		expect(result[3]).to.equal(previous[3])
		expect(result[3]).to.equal(other[2])
	end)

	it("allows observe()", function()
		local items = flec({
			{ key = 1, value = "a" },
			{ key = 2, value = "b" },
			{ key = 3, value = "c" },
		})

		local map = mapped(items, function(item)
			return item, item.key
		end)

		local added = 0
		local deleted = 0

		local stopObserving = observe(map, function(item, key)
			local original = items()[key]
			expect(item).to.equal(original)
			added += 1

			return function()
				local source = map()[key]

				expect(source).to.never.be.ok()
				deleted += 1
			end
		end)

		expect(added).to.equal(3)
		expect(deleted).to.equal(0)

		local previous = items()
		items({ previous[1], previous[3] })

		expect(added).to.equal(3)
		expect(deleted).to.equal(1)

		items({})

		expect(added).to.equal(3)
		expect(deleted).to.equal(3)
		stopObserving()
	end)
end

local types = require(script.Parent.Parent.types)

local mapped = require(script.Parent.Parent.mapped)
local value = require(script.Parent.Parent.value)
local observe = require(script.Parent.Parent.observe)
local subscribe = require(script.Parent.Parent.subscribe)
local peek = require(script.Parent.Parent.peek)
local count = require(script.Parent.Parent.utils.count)

type Array<T> = types.Array<T>
type Map<K, V> = types.Dictionary<K, V>

return function()
	it("returns mapped state", function()
		local updates = 0

		local items = value({ "a", "b", "c" })
		local allUpperCase = mapped(items, function(item)
			return string.upper(item)
		end)

		local unsubscribe = subscribe(allUpperCase, function()
			updates += 1
		end)

		for index = 1, 3 do
			local item = peek(allUpperCase)[index]
			expect(item).to.equal(string.upper(peek(items)[index]))
		end

		items:set({ "a", "b", "c", "d" })
		expect(updates).to.equal(1)

		for index = 1, 4 do
			local item = peek(allUpperCase)[index]
			expect(item).to.equal(string.upper(peek(items)[index]))
		end

		items:set({ "c" })
		expect(updates).to.equal(2)
		expect(peek(allUpperCase)[1]).to.equal(string.upper(peek(items)[1]))

		items:set({ "c", "d" })
		expect(updates).to.equal(3)

		for index = 1, 2 do
			local item = peek(allUpperCase)[index]
			expect(item).to.equal(string.upper(peek(items)[index]))
		end

		items:set({ [1] = "b", [3] = "f" })
		expect(updates).to.equal(4)
		expect(peek(allUpperCase)[2]).to.never.be.ok()

		items:set({})
		expect(updates).to.equal(5)
		expect(count(peek(allUpperCase))).to.equal(0)
		unsubscribe()
	end)

	it("uses key extractor", function()
		local items = value({ { key = 1 }, { key = 2 }, { key = 3 } })
		local map = mapped(items, function(item)
			return item, item.key
		end)

		for key = 1, 3 do
			local item = peek(map)[key]
			expect(item).to.equal(peek(items)[key])
		end

		local previous = peek(map)
		local previousItems = peek(items)
		items:set({ previousItems[1], previousItems[3] })

		expect(peek(map)[1]).to.equal(previous[1])
		expect(peek(map)[1]).to.equal(peek(items)[1])
		expect(peek(map)[2]).to.never.be.ok()
		expect(peek(map)[3]).to.equal(previous[3])
		expect(peek(map)[3]).to.equal(peek(items)[2])
	end)

	it("allows observe()", function()
		local items = value({
			{ key = 1, value = "a" },
			{ key = 2, value = "b" },
			{ key = 3, value = "c" },
		})

		local map = mapped(items, function(item)
			return item, item.key
		end)

		local added = 0
		local deleted = 0

		observe(map, function(item, key)
			expect(item).to.equal(peek(items)[key])
			added += 1

			return function()
				expect(peek(map)[key]).to.never.be.ok()
				deleted += 1
			end
		end)

		expect(added).to.equal(3)
		expect(deleted).to.equal(0)

		local previous = peek(items)
		items:set({ previous[1], previous[3] })

		expect(added).to.equal(3)
		expect(deleted).to.equal(1)

		items:set({})

		expect(added).to.equal(3)
		expect(deleted).to.equal(3)
	end)
end

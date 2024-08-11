local value = require(script.Parent.Parent.value)
local subscribe = require(script.Parent.Parent.subscribe)
local effect = require(script.Parent.Parent.effect)
local computed = require(script.Parent.Parent.computed)
local batch = require(script.Parent.Parent.batch)
local peek = require(script.Parent.Parent.peek)

return function()
	it("batches updates", function()
		local source = value(0)
		local updates = 0

		local unsubscribe = subscribe(source, function()
			updates += 1
		end)

		batch(function(add)
			add(source)

			source:set(2)
			source:set(3)
			source:set(4)
		end)

		expect(updates).to.equal(1)
		updates = 0

		batch(function(add)
			add(source)

			source:set(5)
			source:set(6)
			source:set(7)
		end)

		source:set(8)
		source:set(9)
		source:set(10)

		expect(updates).to.equal(4)
		unsubscribe()
	end)

	it("handles duplicate listeners", function()
		local a = value(1)
		local b = value(1)
		local c = value(1)
		local updates = 0

		effect(function(use)
			use(a)
			use(b)
			use(c)

			updates += 1
		end)

		updates = 0 -- effect() will run once initially

		batch(function(add)
			add(a, b, c)

			a:set(2)
			b:set(2)
			a:set(3)
			c:set(4)
			a:set(5)
		end)

		expect(updates).to.equal(1)
	end)

	it("batches computed state", function()
		local source = value(1)

		local updates = 0
		local computations = 0

		local double = computed(function(use)
			computations += 1
			return use(source) * 2
		end)

		subscribe(double, function()
			updates += 1
		end)

		batch(function(add)
			add(source)

			source:set(2)
			source:set(3)
			source:set(4)
		end)

		expect(updates).to.equal(1)
		expect(computations).to.equal(2)
		expect(peek(double)).to.equal(8)
	end)
end

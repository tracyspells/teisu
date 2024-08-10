local value = require(script.Parent.Parent.value)
local computed = require(script.Parent.Parent.computed)
local untrack = require(script.Parent.Parent.untrack)
local peek = require(script.Parent.Parent.peek)

return function()
	it("memoizes the result", function()
		local calls = 0

		local a = value(0)
		local b = value(1)

		local add = computed(function(use)
			calls += 1

			local numberA = use(a)
			local numberB = use(b)

			local result = numberA + numberB

			return result
		end)

		expect(peek(add)).to.equal(1)
		expect(calls).to.equal(1)

		a:set(function(number)
			return number + 1
		end)

		expect(peek(add)).to.equal(2)
		expect(calls).to.equal(2)

		b:set(function(number)
			return number + 2
		end)
		b:set(function(number)
			return number + 2
		end)

		expect(peek(add)).to.equal(6)
		expect(calls).to.equal(3)
	end)

	it("can be nested", function()
		local source = value(1)
		local double = computed(function(use)
			return use(source) * 2
		end)

		local quadruple = computed(function(use)
			return use(double) * 2
		end)

		expect(peek(quadruple)).to.equal(4)
		source:set(function(number)
			return number + 1
		end)
		expect(peek(quadruple)).to.equal(8)
	end)

	it("can untrack its dependencies", function()
		local source = value(1)
		local double = computed(function(use)
			return use(source) * 2
		end)

		local quadruple = computed(function(use)
			return use(double) * 2
		end)

		expect(peek(quadruple)).to.equal(4)
		untrack(quadruple)
		source:set(2)
		expect(peek(quadruple)).to.equal(4)
		untrack(quadruple) -- no op
		source:set(3)
		expect(peek(quadruple)).to.equal(4)
		expect(peek(double)).to.equal(6)
		untrack(double)
		source:set(4)
		expect(peek(double)).to.equal(6)
	end)
end

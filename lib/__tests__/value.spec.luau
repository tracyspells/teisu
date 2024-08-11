local value = require(script.Parent.Parent.value)
local peek = require(script.Parent.Parent.peek)

return function()
	it("is a state", function()
		local testA = value(0)

		expect(testA).to.be.ok()
		expect(testA).to.be.a("table")

		expect(testA.set).to.be.a("function")
		expect(testA.reset).to.be.a("function")
	end)

	it("edits its stored value", function()
		local source = value(0)

		source:set(function(number)
			return number + 1
		end)

		local result = peek(source)

		expect(result).to.equal(1)

		source:set(function(number)
			return number - 1
		end)

		result = peek(source)

		expect(result).to.equal(0)
	end)

	it("resets to initial state", function()
		local testA = value({ a = 0 })

		for _ = 1, 10 do
			testA:set(function(state)
				return { a = state.a + 1 }
			end)
		end

		local result = peek(testA)

		expect(result.a).to.equal(10)

		testA:reset()
		result = peek(testA)

		expect(result.a).to.equal(0)
	end)

	it("takes a custom equality function", function()
		local max = value(1, {
			equals = function(new, old)
				return new < old
			end,
		})

		max:set(5)
		expect(peek(max)).to.equal(5)
		max:set(2)
		expect(peek(max)).to.equal(5)
		max:set(10)
		expect(peek(max)).to.equal(10)
	end)
end

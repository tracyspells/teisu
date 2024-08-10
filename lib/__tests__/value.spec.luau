local value = require(script.Parent.Parent.value)
local peek = require(script.Parent.Parent.peek)

return function()
	local testA = value({ a = 0 })

	afterEach(function()
		testA:reset()
	end)

	it("is a state", function()
		expect(testA).to.be.ok()
		expect(testA).to.be.a("table")

		expect(testA.set).to.be.a("function")
		expect(testA.reset).to.be.a("function")
	end)

	it("edits its stored value", function()
		testA:set(function(state)
			return { a = state.a + 1 }
		end)

		local result = peek(testA)

		expect(result.a).to.equal(1)

		testA:set(function(state)
			return { a = state.a - 1 }
		end)

		result = peek(testA)

		expect(result.a).to.equal(0)
	end)

	it("resets to initial state", function()
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
end

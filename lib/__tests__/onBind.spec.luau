local value = require(script.Parent.Parent.value)
local onBind = require(script.Parent.Parent.onBind)
local peek = require(script.Parent.Parent.peek)

return function()
	it("calls the specified callback immediately", function()
		local a = value(10)
		local result

		onBind(a, function(number)
			result = number
		end)

		expect(result).to.equal(10)
	end)

	it("returns a cleanup function", function()
		local counter = value(0)

		local disconnect = onBind(counter, function()
			-- do nothing
		end)

		expect(disconnect).to.be.ok()
		expect(disconnect).to.be.a("function")

		disconnect()
	end)

	it("listens for changes", function()
		local a = value(10)
		local initialA = peek(a)
		local newA, oldA

		onBind(a, function(new, old)
			newA, oldA = new, old
		end)

		expect(newA).to.equal(oldA)
		a:set(20)
		expect(newA).to.equal(peek(a))
		expect(oldA).to.equal(initialA)
		expect(newA).to.never.equal(oldA)
	end)
end

local untrack = require(script.Parent.Parent.untrack)
local computed = require(script.Parent.Parent.computed)
local value = require(script.Parent.Parent.value)
local peek = require(script.Parent.Parent.peek)

return function()
	it("untracks a computed object", function()
		local a = value(0)
		local b = computed(function(use)
			return use(a) * 5
		end)

		expect(peek(b)).to.equal(0)
		untrack(b)

		a:set(1)
		expect(peek(b)).to.equal(0)
	end)
end

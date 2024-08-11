local untrack = require(script.Parent.Parent.untrack)
local computed = require(script.Parent.Parent.computed)
local value = require(script.Parent.Parent.value)

return function()
	it("untracks a computed object", function()
		local a = value(0)
		local b = computed(function(use)
			return use(a) * 5
		end)

		expect(function()
			untrack(b)
		end).to.be.ok()
	end)

	it("handles non-computed objects", function()
		local source = value(1)

		expect(function()
			untrack(source)
		end).to.throw()

		expect(function()
			untrack("hi")
		end).to.throw()
	end)
end

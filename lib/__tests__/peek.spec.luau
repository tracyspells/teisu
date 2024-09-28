local peek = require(script.Parent.Parent.peek)
local flec = require(script.Parent.Parent.flec)
local computed = require(script.Parent.Parent.computed)
local utils = require(script.Parent.Parent.utils)
local graph = require(script.Parent.Parent.graph)

local count = utils.count

return function()
	it("will not track dependencies", function()
		local counter = flec(1)

		local multiplier = flec(2)
		local node = graph.castToReactable(multiplier)

		local double = computed(function()
			return counter() * peek(multiplier)
		end)

		expect(double()).to.equal(2)

		if node ~= nil then
			expect(count(node.parents)).to.equal(0)
			expect(count(node.children)).to.equal(0)
		end

		counter(2)

		expect(double()).to.equal(4)

		if node ~= nil then
			expect(count(node.parents)).to.equal(0)
			expect(count(node.children)).to.equal(0)
		end

		expect(peek(double)).to.equal(4)
	end)

	it("returns the value if it's not a molecule", function()
		local function noop() end

		expect(peek("hi")).to.equal("hi")
		expect(peek(25)).to.equal(25)
		expect(peek(noop)).to.equal(noop)
	end)
end

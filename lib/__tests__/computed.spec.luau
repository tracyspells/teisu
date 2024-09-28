local utils = require(script.Parent.Parent.utils)
local graph = require(script.Parent.Parent.graph)
local flec = require(script.Parent.Parent.flec)
local computed = require(script.Parent.Parent.computed)

local collect = utils.collect
local count = utils.count

return function()
	it("memoizes the result", function()
		local calls = 0

		local a = flec(0)
		local b = flec(1)

		local add = computed(function()
			calls += 1
			return a() + b()
		end)

		expect(add()).to.equal(1)
		expect(calls).to.equal(1)

		a(function(number)
			return number + 1
		end)

		expect(add()).to.equal(2)
		expect(calls).to.equal(2)

		b(function(number)
			return number + 2
		end)
		b(function(number)
			return number + 2
		end)

		expect(add()).to.equal(6)
		expect(calls).to.equal(3)
	end)

	it("can be nested", function()
		local source = flec(1)
		local double = computed(function()
			return source() * 2
		end)

		local quadruple = computed(function()
			return double() * 2
		end)

		expect(quadruple()).to.equal(4)
		source(function(number)
			return number + 1
		end)
		expect(quadruple()).to.equal(8)
	end)
	
	it("gets garbage collected", function()
		local source = flec(0)
		local node = graph.castToReactable(source) 

		computed(function()
			return source()
		end)

		collect()
		expect(count((node :: any).children)).to.equal(0)
	end)

	it("garbage collects nested computed objects", function()
		local source = flec(0)
		local node = graph.castToReactable(source) 

		do
			local double = computed(function()
				return source() * 2
			end)

			computed(function()
				return double() * 2
			end)
		end

		collect()
		expect(count((node :: any).children)).to.equal(0)
	end)

	it("tracks conditional dependencies", function()
		local condition = flec(false)
		local a = flec(0)
		local b = flec(1)

		local reruns = 0
		local current

		local dependencies = computed(function()
			reruns += 1
			current = if condition() then a() else b()

			return current
		end)

		-- we need to call peek before every 'expect()' because
		-- 'computed()' does lazy execution (i.e. only computes when needed)
		dependencies()
		expect(reruns).to.equal(1)
		expect(current).to.equal(1)

		condition(true)
		dependencies()
		expect(reruns).to.equal(2)
		expect(current).to.equal(0)

		a(1)
		b(2)
		dependencies()
		expect(reruns).to.equal(3)
		expect(current).to.equal(1)

		condition(false)
		dependencies()
		expect(reruns).to.equal(4)
		expect(current).to.equal(2)
	end)
end

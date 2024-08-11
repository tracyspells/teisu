local value = require(script.Parent.Parent.value)
local computed = require(script.Parent.Parent.computed)
local untrack = require(script.Parent.Parent.untrack)
local peek = require(script.Parent.Parent.peek)
local collect = require(script.Parent.Parent.utils.collect)
local count = require(script.Parent.Parent.utils.count)

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

	it("allows untrack()", function()
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

	it("gets garbage collected", function()
		local source = value(0)

		computed(function(use)
			return use(source)
		end)

		collect()
		expect(count(source.children)).to.equal(0)
	end)

	it("garbage collects nested computed objects", function()
		local source = value(0)

		do
			local double = computed(function(use)
				return use(source) * 2
			end)

			computed(function(use)
				return use(double) * 2
			end)
		end

		collect()
		expect(count(source.children)).to.equal(0)
	end)

	it("tracks conditional dependencies", function()
		local condition = value(false)
		local a = value(0)
		local b = value(1)

		local reruns = 0
		local current

		local dependencies = computed(function(use)
			reruns += 1
			current = if use(condition) then use(a) else use(b)

			return current
		end)

		-- we need to call peek before every 'expect()' because
		-- 'computed()' does lazy execution (i.e. only computes when needed)
		peek(dependencies)
		expect(reruns).to.equal(1)
		expect(current).to.equal(1)

		condition:set(true)
		peek(dependencies)
		expect(reruns).to.equal(2)
		expect(current).to.equal(0)

		a:set(1)
		b:set(2)
		peek(dependencies)
		expect(reruns).to.equal(2)
		expect(current).to.equal(0)

		condition:set(false)
		peek(dependencies)
		expect(reruns).to.equal(3)
		expect(current).to.equal(2)
	end)
end

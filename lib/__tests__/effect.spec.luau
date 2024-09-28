local effect = require(script.Parent.Parent.effect)
local flec = require(script.Parent.Parent.flec)

return function()
	it("watches flecs", function()
		local a = flec(0)
		local b = flec(0)

		local result = 0

		local dispose = effect(function()
			result = a() + b()
		end)

		expect(result).to.equal(0)

		for index = 1, 3 do
			a(index)
			expect(result).to.equal(index)
		end

		for _ = 1, 3 do
			b(b() + 1)
		end

		dispose()
		a(10)
		expect(result).to.equal(6)
	end)

	it("accepts a cleanup function", function()
		local a = flec(0)

		local cleanups = 0

		local dispose = effect(function()
			a()

			return function()
				cleanups += 1
			end
		end)

		expect(cleanups).to.equal(0)
		a(1)
		expect(cleanups).to.equal(1)
		dispose()
		expect(cleanups).to.equal(2)
	end)

	it("tracks conditional dependencies", function()
		local condition = flec(false)
		local a = flec(0)
		local b = flec(1)

		local reruns = 0
		local current

		effect(function()
			reruns += 1
			current = if condition() then a() else b()
		end)

		expect(reruns).to.equal(1)
		expect(current).to.equal(1)

		condition(true)
		expect(reruns).to.equal(2)
		expect(current).to.equal(0)

		a(1)
		b(2)
		expect(reruns).to.equal(3)
		expect(current).to.equal(1)

		condition(false)
		expect(reruns).to.equal(4)
		expect(current).to.equal(2)
	end)

	it("accepts functions with no dependencies", function()
		local initialized = false
		local cleaned = false

		local dispose = effect(function()
			initialized = true

			return function()
				cleaned = true
			end
		end)

		expect(initialized).to.equal(true)
		dispose()
		expect(cleaned).to.equal(true)
	end)

	it("allows self-cleanup", function()
		local a = flec(0)
		local disposed = false
		local dispose

		dispose = effect(function()
			if dispose then
				assert(not disposed, "cleanup ran twice")
				dispose()
				disposed = true
			end

			a()
		end)

		a(2)
		a(3)
	end)
end

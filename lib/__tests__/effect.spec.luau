local effect = require(script.Parent.Parent.effect)
local value = require(script.Parent.Parent.value)

return function()
	it("watches state objects", function()
		local a = value(0)
		local b = value(0)

		local result

		local dispose = effect(function(use)
			result = use(a) + use(b)
		end)

		expect(result).to.equal(0)

		for index = 1, 3 do
			a:set(index)
			expect(result).to.equal(index)
		end

		for index = 1, 3 do
			b:set(function(number) return number + 1 end)
		end

		dispose()
		a:set(10)
		expect(result).to.equal(3)
	end)

	it("accepts a cleanup function", function()
		local a = value(0)

		local cleanups = 0

		local dispose = effect(function(use)
			use(a)

			return function()
				cleanups += 1
			end
		end)

		expect(cleanups).to.equal(0)
		a:set(1)
		expect(cleanups).to.equal(1)
		dispose()
		expect(cleanups).to.equal(2)
	end)

	it("tracks conditional dependencies", function()
		local condition = value(false)
		local a = value(0)
		local b = value(1)

		local reruns = 0
		local current

		effect(function(use)
			reruns += 1
			current = if use(condition) then use(a) else use(b)
		end)

		expect(reruns).to.equal(1)
		expect(current).to.equal(1)

		condition:set(true)
		expect(reruns).to.equal(2)
		expect(current).to.equal(0)

		a:set(1)
		b:set(2)
		expect(reruns).to.equal(2)
		expect(current).to.equal(0)

		condition:set(false)
		expect(reruns).to.equal(3)
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
		local a = value(0)
		local disposed = false
		local dispose

		dispose = effect(function(use)
			if dispose then
				assert(not disposed, "cleanup ran twice")
				dispose()
				disposed = true
			end

			use(a)
		end)

		a:set(2)
		a:set(3)
	end)

	it("allows nested effects", function()
		local isCleaned = false
		local shouldCleanup = value(false)

		local disposeOuter
		disposeOuter = effect(function()
			local disposeInner
			disposeInner = effect(function(use)
				if disposeInner then
					assert(not isCleaned, "cleanup ran twice")
					disposeInner()
					isCleaned = true
				end

				use(shouldCleanup)

				return function()
					disposeOuter()
				end
			end)
		end)

		shouldCleanup:set(true)
		shouldCleanup:set(false)
		shouldCleanup:set(true)
	end)
end

local flec = require(script.Parent.Parent.flec)
local subscribe = require(script.Parent.Parent.subscribe)

return function()
	it("returns a cleanup function", function()
		local counter = flec(0)

		local unsubscribe = subscribe(counter, function()
			-- do nothing
		end)

		expect(unsubscribe).to.be.ok()
		expect(unsubscribe).to.be.a("function")

		unsubscribe()
	end)

	it("calls the listener when state changes", function()
		local counter = flec(0)
		local changes = 0

		local unsubscribe = subscribe(counter, function()
			changes += 1
		end)

		expect(changes).to.equal(0)

		counter(function(count) return count + 1 end)
		
		expect(changes).to.equal(1)

		counter(function(count) return count + 1 end)

		expect(changes).to.equal(2)

		changes = 0
		
		counter(1)
		counter(2)
		counter(3)

		expect(changes).to.equal(3)
		unsubscribe()
	end)

	it("passes old and new contents to the listener", function()
		local counter = flec(0)
		local initialState = counter()
		local newState, oldState

		local unsubscribe = subscribe(counter, function(new, old)
			newState = new
			oldState = old
		end)

		counter(1)

		expect(oldState).to.equal(initialState)
		expect(newState).to.equal(counter())
		expect(newState).to.never.equal(oldState)

		unsubscribe()
	end)

	it("allows self-cleanup", function()
		local counter = flec(0)

		local disconnected = false
		local unsubscribe

		unsubscribe = subscribe(counter, function()
			if unsubscribe then
				assert(not disconnected, "disconnect ran twice")
				unsubscribe()
				disconnected = true
			end
		end)

		counter(2)
		counter(3)
	end)
end

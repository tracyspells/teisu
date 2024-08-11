local value = require(script.Parent.Parent.value)
local subscribe = require(script.Parent.Parent.subscribe)
local peek = require(script.Parent.Parent.peek)

return function()
	it("returns a cleanup function", function()
		local counter = value(0)

		local unsubscribe = subscribe(counter, function()
			-- do nothing
		end)

		expect(unsubscribe).to.be.ok()
		expect(unsubscribe).to.be.a("function")

		unsubscribe()
	end)

	it("calls the listener when state changes", function()
		local counter = value(0)
		local changes = 0

		subscribe(counter, function()
			changes += 1
		end)

		expect(changes).to.equal(0)
		counter:set(function(count)
			return count + 1
		end)
		expect(changes).to.equal(1)
		counter:set(function(count)
			return count + 1
		end)
		expect(changes).to.equal(2)

		changes = 0

		counter:set(1)
		counter:set(2)
		counter:set(3)

		expect(changes).to.equal(3)
	end)

	it("passes old and new contents to the listener", function()
		local counter = value(0)
		local initialState = peek(counter)
		local newState, oldState

		subscribe(counter, function(new, old)
			newState = new
			oldState = old
		end)

		counter:set(1)

		expect(oldState).to.equal(initialState)
		expect(newState).to.equal(peek(counter))
		expect(newState).to.never.equal(oldState)
	end)

	it("allows self-cleanup", function()
		local counter = value(0)

		local disconnected = false
		local unsubscribe

		unsubscribe = subscribe(counter, function()
			if unsubscribe then
				assert(not disconnected, "disconnect ran twice")
				unsubscribe()
				disconnected = true
			end
		end)

		counter:set(2)
		counter:set(3)
	end)
end

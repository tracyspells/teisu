local value = require(script.Parent.Parent.value)
local subscribe = require(script.Parent.Parent.subscribe)
local effect = require(script.Parent.Parent.effect)
local computed = require(script.Parent.Parent.computed)
local batch = require(script.Parent.Parent.batch)
local peek = require(script.Parent.Parent.peek)

return function()
    it("batches updates", function() 
        local source = value(0)
        local updates = 0
        
        local unsubscribe = subscribe(source, function()
            updates += 1
        end)

        batch(function(add)
            add(source)

            source:set(2)
            source:set(3)
            source:set(4)
        end)

        expect(updates).to.equal(1)
        unsubscribe()
    end)

    it("handles duplicate listeners", function()
		local a = value(1)
		local b = value(1)
		local updates = 0

		effect(function(use)
            updates += 1
            use(a)
            use(b)
		end)

		updates = 0 -- effect() will run once initially

		batch(function(add)
            add(a, b)

			a:set(2)
			b:set(2)
			a:set(3)
		end)

		expect(updates).to.equal(1)
	end)

    it("handles non-state objects", function()  
        expect(function()
            batch(function(add)
                add(1 :: any, "true" :: any, true :: any)
            end)
        end).to.throw()
    end)

	it("handles empty callbacks", function()  
		expect(function()
			batch(function(_)

			end)
		end).to.never.throw()
	end)

    it("batches computed state", function()
		local source = value(1)

		local updates = 0
		local computations = 0

		local double = computed(function(use)
			computations += 1
			return use(source) * 2
		end)

		subscribe(double, function()
			updates += 1
		end)

		batch(function(add)
            add(source)

			source:set(2)
			source:set(3)
			source:set(4)
		end)

		expect(updates).to.equal(1)
		expect(computations).to.equal(2)
		expect(peek(double)).to.equal(8)
	end)
end

local flec = require(script.Parent.Parent.flec)
local subscribe = require(script.Parent.Parent.subscribe)
local effect = require(script.Parent.Parent.effect)
local batch = require(script.Parent.Parent.batch)

return function()
	it("batches updates of one dependency", function()
		local source = flec(0)

		local updates = 0
		local result = nil

		local unsubscribe = subscribe(source, function(new, old)
			updates += 1
			result = new
		end)

		batch(function()
			source(2)
			source(3)
			source(4)
		end)
		
		expect(updates).to.equal(1)
		expect(result).to.equal(4)

		batch(function()
			source(5)
			source(6)
			source(7)
		end)

		expect(updates).to.equal(2)
		expect(result).to.equal(7)
		
		unsubscribe()
	end)

	it("batches updates of multiple dependencies", function()
		local a = flec(1)
		local b = flec(1)
		local c = flec(1)

		local updates = 0
		local resultA, resultB, resultC

		local dispose = effect(function()
			resultA = a()
			resultB = b()
			resultC = c()

			updates += 1
		end)

		updates = 0 -- effect() will run once initially

		batch(function()
			a(2)
			b(2)
			a(3)
			c(4)
			a(5)
		end)

		expect(updates).to.equal(1)
		expect(resultA).to.equal(5)
		expect(resultB).to.equal(2)
		expect(resultC).to.equal(4)

		batch(function()
			a(5)
			b(6)
			a(7)
			b(9)
		end)

		expect(updates).to.equal(2)
		expect(resultA).to.equal(7)
		expect(resultB).to.equal(9)
		expect(resultC).to.equal(4)

		dispose()
	end)

	it("allows nested batching", function() 
		local a = flec(0)
		local b = flec(0)
		local c = flec(0)
		local d = flec(2)

		local updates = 0
		local resultA, resultB, resultC, resultD

		local dispose = effect(function()
			resultA = a()
			resultB = b()
			resultC = c()
			resultD = d()

			updates += 1
		end)

		updates = 0

		batch(function()  
			a(2)

			batch(function()
				b(4) 

				d(function(num)
					return num * 5
				end)
			end)

			c(3)
		end)
		
		expect(updates).to.equal(1)

		expect(resultA).to.equal(2)
		expect(resultB).to.equal(4)
		expect(resultC).to.equal(3)
		expect(resultD).to.equal(10)

		dispose()
	end)
end

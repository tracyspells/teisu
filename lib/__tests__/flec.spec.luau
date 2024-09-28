local flec = require(script.Parent.Parent.flec)

return function()
	it("is a flec", function()
		local testA = flec(0)

		expect(testA).to.be.ok()
		expect(testA).to.be.a("function")
	end)

	it("edits its stored value", function()
		local source = flec(0)

		source(function(number)
			return number + 1
		end)

		expect(source()).to.equal(1)

		source(function(number)
			return number - 1
		end)

		expect(source()).to.equal(0)

		source(2)
		expect(source()).to.equal(2)
	end)


	it("takes a custom equality function", function()
		local max = flec(0, {
			equals = function(old, new)
				return new < old
			end,
		})

		max(5)
		expect(max()).to.equal(5)
		max(2)
		expect(max()).to.equal(5)
		max(10)
		expect(max()).to.equal(10)
	end)
end

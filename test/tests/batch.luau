local teisu = require("../../lib/init")

local flec = teisu.flec
local batch = teisu.batch
local subscribe = teisu.subscribe
local effect = teisu.effect

type CASE = (name: string) -> ()
type CHECK = <T>(value: T) -> T

return function(CASE: CASE, CHECK: CHECK)
	do
		CASE("batch updates of one dependency")

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

		CHECK(updates == 1)
		CHECK(result == 4)

		batch(function()
			source(5)
			source(6)
			source(7)
		end)

		CHECK(updates == 2)
		CHECK(result == 7)

		unsubscribe()
	end

	do
		CASE("batch updates of multiple dependencies")

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

		CHECK(updates == 1)
		CHECK(resultA == 5)
		CHECK(resultB == 2)
		CHECK(resultC == 4)

		batch(function()
			a(5)
			b(6)
			a(7)
			b(9)
		end)

		CHECK(updates == 2)
		CHECK(resultA == 7)
		CHECK(resultB == 9)
		CHECK(resultC == 4)

		dispose()
	end

	do
		CASE("nested batching")

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

		CHECK(updates == 1)
		CHECK(resultA == 2)
		CHECK(resultB == 4)
		CHECK(resultC == 3)
		CHECK(resultD == 10)

		dispose()
	end
end

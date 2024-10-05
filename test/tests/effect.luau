local teisu = require("../../lib/init")

local flec = teisu.flec
local effect = teisu.effect

type CASE = (name: string) -> ()
type CHECK = <T>(value: T) -> T

return function(CASE: CASE, CHECK: CHECK)
	do
		CASE("rerun on flec change")

		local a = flec(0)

		local result = 0

		local dispose = effect(function()
			result = a()
		end)

		CHECK(result == 0)

		for index = 1, 3 do
			a(index)

			CHECK(result == index)
		end

		a(10)
		CHECK(result == 10)

		dispose()
	end

	do
		CASE("rerun on multiple flec change")

		local a = flec(0)
		local b = flec(0)

		local result = 0

		local dispose = effect(function()
			result = a() + b()
		end)

		CHECK(result == 0)

		for index = 1, 3 do
			a(index)

			CHECK(result == index)
		end

		for index = 1, 3 do
			b(index)
		end

		CHECK(result == 6)

		a(10)
		b(10)

		CHECK(result == 20)

		dispose()
	end

	do
		CASE("cleanup effects")

		local a = flec(0)

		local cleanups = 0

		local dispose = effect(function()
			a()

			return function()
				cleanups += 1
			end
		end)

		CHECK(cleanups == 0)
		a(1)
		CHECK(cleanups == 1)
		dispose()
		CHECK(cleanups == 2)
	end

	do
		CASE("effect self-cleanup")

		local a = flec(0)
		local disposed = false
		local dispose

		dispose = effect(function()
			if dispose then
				CHECK(not disposed)
				dispose()
				disposed = true
			end

			a()
		end)

		a(2)
		a(3)
	end

	do
		CASE("effect lifecycles")

		local mounted = false
		local disposed = false

		local dispose = effect(function()
			mounted = true

			return function()
				disposed = true
			end
		end)

		CHECK(mounted == true)
		dispose()
		CHECK(disposed == true)
	end

	do
		CASE("conditional dependencies")

		local condition = flec(false)
		local a = flec(0)
		local b = flec(1)

		local reruns = 0
		local current

		effect(function()
			reruns += 1
			current = if condition() then a() else b()
		end)

		CHECK(reruns == 1)
		CHECK(current == 1)

		condition(true)

		CHECK(reruns == 2)
		CHECK(current == 0)

		a(1)
		b(2)

		CHECK(reruns == 3)
		CHECK(current == 1)

		condition(false)

		CHECK(reruns == 4)
		CHECK(current == 2)
	end
end

local teisu = require("../../lib/init")
local types = require("../types")
--local count = require("../utils/count")

local flec = teisu.flec
local computed = teisu.computed

--local castToNode = graph.castToReactable

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
	do
		CASE("lowercase V")

		--[[

                a     b
                 ↘   ↙
                   c
        ]]

		local a = flec(0)
		local b = flec(0)

		local calls = 0

		local c = computed(function()
			calls += 1

			return a() * b()
		end)

		CHECK(c() == 0)

		a(function(num)
			return num + 1
		end)

		b(function(num)
			return num + 1
		end)

		CHECK(c() == 1)

		a(b() * 5)
		b(a() * 2)

		CHECK(c() == 50)
		CHECK(calls == 3)
	end

	do
		CASE("y")

		--[[

                a     b
                 ↘   ↙
                   c
                   ↓
                   d
        ]]

		local a = flec(0)
		local b = flec(0)

		local cCalls = 0
		local c = computed(function()
			cCalls += 1

			return a() * b()
		end)

		local dCalls = 0
		local d = computed(function()
			dCalls += 1

			return c() * 10
		end)

		CHECK(d() == 0)

		a(function(num)
			return num + 1
		end)

		b(function(num)
			return num + 1
		end)

		CHECK(d() == 10)

		a(b() * 5)
		b(a() * 2)

		CHECK(d() == 500)

		CHECK(cCalls == 3)
		CHECK(dCalls == 3)
	end

	do
		CASE("diamond")

		--[[

                  a  
                ↙   ↘
                b    c
                ↘   ↙
                  d
        ]]

		local a = flec(0)

		local bCalls = 0
		local b = computed(function()
			bCalls += 1
			return a() * 2
		end)

		local cCalls = 0
		local c = computed(function()
			cCalls += 1

			return a() * 3
		end)

		local dCalls = 0
		local d = computed(function()
			dCalls += 1
			return b() * c()
		end)

		CHECK(d() == 0)

		a(1)

		CHECK(b() == 2)
		CHECK(c() == 3)
		CHECK(d() == 6)

		a(2)

		CHECK(b() == 4)
		CHECK(c() == 6)
		CHECK(d() == 24)

		a(function(num)
			return num * 3
		end)

		CHECK(b() == 12)
		CHECK(c() == 18)
		CHECK(d() == 216)

		CHECK(bCalls == 4)
		CHECK(cCalls == 4)
		CHECK(dCalls == 4)
	end
end

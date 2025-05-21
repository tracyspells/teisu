local teisu = require("../../lib/init")
local teisu_types = require("../../lib/types")
local types = require("../types")
local testkit = require("../testkit")

local flec = teisu.flec
local new = teisu.new
local indexes = teisu.indexes
local cleanup = teisu.cleanup
local equals = testkit.seq

type Node<T> = teisu_types.Node<T>

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
	do
		CASE("computes with constants")

		local data = {"oof", "rab"}
		local map = indexes(data, function(value, i)
			return `{i()}{value}`
		end)

		local result = map()
		CHECK(equals(result, { "1oof",  "2rab" }))
		cleanup(map)
	end

	do
		CASE("caches result")

		local input = flec { 1, 2, 3 }

        local count = table.create(3, 0)

        local output = indexes(input, function(v, i)
            count[v] += 1
            return i
        end)

		local result = output()
		
        input { 1, 3, 2 }

		result = output()
	
        CHECK(result[1]() == 1)
        CHECK(result[2]() == 3)
        CHECK(result[3]() == 2)

        CHECK(count[1] == 2)
        CHECK(count[2] == 2)
        CHECK(count[3] == 2)
	end

	do
		CASE("additions and removals")

		local input = flec { 1, 2, 3 }
		local destroyed = 0
		local output = indexes(input, function(value)
			cleanup(function() destroyed += 1 end)

			return new "TextLabel" {
				Text = `{value}`
			}
		end)

		local result = output()

		input { 1, 2 }

		result = output()
		CHECK(result[1].Text == `1`)
		CHECK(result[2].Text == `2`)
		CHECK(result[3] == nil :: never)
		CHECK(destroyed == 1)

		input { 1, 2, 3 }

		result = output()
		CHECK(result[1].Text == `1`)
		CHECK(result[2].Text == `2`)
		CHECK(result[3].Text == `3`)

		cleanup(output)
		CHECK(destroyed == 4)
	end
end

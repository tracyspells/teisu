local teisu = require("../../lib/init")
local teisu_types = require("../../lib/types")
local types = require("../types")
local testkit = require("../testkit")

local flec = teisu.flec
local new = teisu.new
local keys = teisu.keys
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

		local data = {foo = "oof", bar = "rab"}
		local map = keys(data, function(key)
			return `{key}baz`
		end)

		local result = map()
		CHECK(equals(result, { foobaz = "oof", barbaz = "rab" }))
		cleanup(map)
	end

	do
		CASE("returns nothing if user doesn't provide a transformed key")

		local data = {foo = "oof", bar = "rab"}
		local map = keys(data, function()
			return nil
		end)

		local result = map()
		CHECK(equals(result, {}))
		cleanup(map)
	end

	do
		CASE("produces the same updated keys even if a key's value changes")

		local input = flec({ foo = "oof", bar = "rab" })
		local map = keys(input, function(key)
			return string.upper(key)
		end)

		local EXPECTED = { FOO = 'oof', BAR = "rab" }

		local result = map()
		CHECK(equals(result, EXPECTED))

		input(function(old)
			local new = table.clone(old)
			new.foo = "ahh"
			return new
		end)

		result = map()
		CHECK(equals(result, EXPECTED))
		cleanup(map)
	end

	do
		CASE("additions and removals")

		local input = flec({ foo = "oof", bar = "rab" })
		local map = keys(input, function(key)
			return string.upper(key)
		end)

		local result = map()
		CHECK(equals(result, { FOO = 'oof', BAR = "rab" }))

		input(function(old)
			local new = table.clone(old)
			new.foo = nil :: never
			return new
		end)

		result = map()
		CHECK(equals(result, { BAR = "rab" }))

		input(function(old)
			local new = table.clone(old)
			new.foo = "hi"
			return new
		end)

		result = map()
		CHECK(equals(result, { FOO = "hi", BAR = "rab" }))

		cleanup(map)
	end

	do
		CASE("mapper function does not allow the user to return an Instance")

		teisu.strict(true)
		CHECK_EXPECT_ERROR(function()
			local input = flec({ foo = "oof", bar = "rab" })

			keys(input, function(key)
				return new "TextLabel" {
					Name = string.upper(key),
				}
			end)()
		end)
		teisu.strict(false)
	end

	do
		CASE("cleans up connections when a key is removed")

		local removed: { [string]: boolean } = {}

		local input = flec({ foo = "oof", bar = "rab" } :: { [string]: string? })
		local map = keys(input, function(key)
			cleanup(function()
				removed[key] = true
			end)

			return string.upper(key)
		end)

		map() -- populate the table

		input { foo = 'oof' }
		map()

		CHECK(equals(removed, { bar = true }))
		
		input {}
		map()

		CHECK(equals(removed, { foo = true, bar = true }))
	end
end

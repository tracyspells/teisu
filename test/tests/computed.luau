local teisu = require("../../lib/init")
local teisu_graph = require("../../lib/graph")
local teisu_types = require("../../lib/types")
local types = require("../types")
local testkit = require("../testkit")

local flec = teisu.flec
local computed = teisu.computed
local cleanup = teisu.cleanup
local equals = testkit.seq

type CASE = types.CASE
type CHECK = types.CHECK

type Node<T> = teisu_types.Node<T>

return function(CASE: CASE, CHECK: CHECK)
	do
		CASE("caches results")

		local calls = 0

		local a = flec(0)
		local b = flec(1)

		local add = computed(function()
			calls += 1
			return a() + b()
		end)

		CHECK(add() == 1)
		CHECK(calls == 1)

		a(function(number)
			return number + 1
		end)

		CHECK(add() == 2)
		CHECK(calls == 2)

		b(function(number)
			return number + 2
		end)
		b(function(number)
			return number + 2
		end)

		CHECK(add() == 6)
		CHECK(calls == 3)
	end

	do
		CASE("nested computeds")

		local source = flec(1)
		local double = computed(function()
			return source() * 2
		end)

		local quadruple = computed(function()
			return double() * 2
		end)

		CHECK(quadruple() == 4)

		source(function(number)
			return number + 1
		end)

		CHECK(quadruple() == 8)
	end

	do
		CASE("can be cleaned up")

		local source = flec("hello")
		local uppercase = computed(function()
			return string.upper(source())  
		end)

		local computed_node: Node<string> = uppercase(teisu_graph.NODE_KEY :: any) :: any

		uppercase()
		CHECK(not equals(computed_node.parents, {})) -- check if `uppercase`'s parents arent empty
		cleanup(uppercase)
		source("bye")
		CHECK(uppercase() ~= source())
		computed_node = nil :: never
	end

	do
		CASE("conditional dependencies")

		local condition = flec(false)
		local a = flec(0)
		local b = flec(1)

		local reruns = 0
		local current

		local dependencies = computed(function()
			reruns += 1
			current = if condition() then a() else b()

			return current
		end)

		-- we need to call peek before every 'expect()' because
		-- 'computed()' does lazy execution (i.e. only computes when needed)
		dependencies()
		CHECK(reruns == 1)
		CHECK(current == 1)

		condition(true)
		dependencies()
		CHECK(reruns == 2)
		CHECK(current == 0)

		a(1)
		b(2)
		dependencies()
		CHECK(reruns == 3)
		CHECK(current == 1)

		condition(false)
		dependencies()
		CHECK(reruns == 4)
		CHECK(current == 2)
	end
end

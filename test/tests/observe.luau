local teisu = require("../../lib/init")
local types = require("../types")

local flec = teisu.flec
local observe = teisu.observe

type Array<T> = { T }
type Map<K, V> = { [K]: V }

type Todo = "Wake up" | "Brush teeth" | "Take shower"

local TODOS: Array<Todo> = {
	"Wake up",
	"Brush teeth",
	"Take shower",
}

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
	do
		CASE("entity lifecycle")

		local result: Map<number, Todo> = {}

		local todos = flec({})
		
		local stopObserving = observe(todos, function(todo, index)
			result[index] = todo
			
			return function()
				if result[index] then
					result[index] = nil
				end
			end
		end)

		for index = 1, #TODOS do
			CHECK(result[index] == nil)
		end

		for _, todo in TODOS do
			todos(function(oldTodos)
				local newTodos = table.clone(oldTodos)
				table.insert(newTodos, todo)

				return newTodos
			end)
		end

		for index = 1, #TODOS do
			CHECK(result[index] ~= nil)
			CHECK(result[index] == todos()[index])
		end

		todos(function(oldTodos)
			local newTodos = table.clone(oldTodos)
			table.clear(newTodos)

			return newTodos
		end)

		for index = 1, #TODOS do
			CHECK(result[index] == nil)
		end

		stopObserving()
	end
end

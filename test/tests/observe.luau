local teisu = require("../../lib/init")
local types = require("../types")

local flec = teisu.flec
local observe = teisu.observe

type Array<T> = { T }
type Map<K, V> = { [K]: V }

type CASE = types.CASE
type CHECK = types.CHECK

type Todo = "Wake up" | "Brush teeth" | "Take shower"

local TODOS: Array<Todo> = {
	"Wake up",
	"Brush teeth",
	"Take shower",
}

return function(CASE: CASE, CHECK: CHECK)
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

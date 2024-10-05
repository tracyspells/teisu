local teisu = require("../../lib/init")

local flec = teisu.flec
local observe = teisu.observe

type Array<T> = { T }
type Map<K, V> = { [K]: V }

type CASE = (name: string) -> ()
type CHECK = <T>(value: T) -> T

type Todo = "Wake up" | "Brush teeth" | "Take shower"

local TODOS: Array<Todo> = {
	"Wake up",
	"Brush teeth",
	"Take shower",
}

return function(CASE: CASE, CHECK: CHECK)
	do
		CASE("entity lifecycle")

		local todos = flec({})
		local result: Map<number, Todo> = {}

		local stopObserving = observe(todos, function(todo, index)
			result[index] = todo

			return function()
				if result[index] then
					result[index] = nil
				end
			end
		end)

		for _, todo in TODOS do
			todos(function(oldTodos)
				local newTodos = table.clone(oldTodos)
				table.insert(newTodos, todo)

				return newTodos
			end)
		end

		local current = todos()

		for index = 1, #TODOS do
			CHECK(result[index] ~= nil)
			CHECK(result[index] == current[index])
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

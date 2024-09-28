local types = require(script.Parent.Parent.types)
local flec = require(script.Parent.Parent.flec)
local observe = require(script.Parent.Parent.observe)

type Array<T> = types.Array<T>
type Map<K, V> = types.Map<K, V>

type Todo = "Wake up" | "Brush teeth" | "Take shower"

local TODOS: Array<Todo> = {
	"Wake up",
	"Brush teeth",
	"Take shower",
}

return function()
	it("observes lifetime of entities", function()
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
			expect(result[index]).to.be.ok()
			expect(result[index]).to.equal(current[index])
		end

		todos(function(oldTodos)
			local newTodos = table.clone(oldTodos)
			table.clear(newTodos)

			return newTodos
		end)

		for index = 1, #TODOS do
			expect(result[index]).to.equal(nil)
		end

		stopObserving()
	end)
end

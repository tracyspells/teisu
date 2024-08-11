local types = require(script.Parent.Parent.types)

local value = require(script.Parent.Parent.value)
local observe = require(script.Parent.Parent.observe)
local peek = require(script.Parent.Parent.peek)

type Array<T> = types.Array<T>
type Dictionary<Key, Value> = types.Dictionary<Key, Value>

type Todo = "Wake up" | "Brush teeth" | "Take shower"

local TODOS: Array<Todo> = {
	"Wake up",
	"Brush teeth",
	"Take shower",
}

return function()
	it("observes lifetime of entities", function()
		local todos = value({})
		local result: Dictionary<number, Todo> = {}

		observe(todos, function(todo, index)
			result[index] = todo

			return function()
				if result[index] then
					result[index] = nil
				end
			end
		end)

		for _, todo in TODOS do
			todos:set(function(oldTodos)
				local newTodos = table.clone(oldTodos)
				table.insert(newTodos, todo)

				return newTodos
			end)
		end

		local current = peek(todos)

		for index = 1, #TODOS do
			expect(result[index]).to.be.ok()
			expect(result[index]).to.equal(current[index])
		end

		todos:set(function(oldTodos)
			local newTodos = table.clone(oldTodos)
			table.clear(newTodos)

			return newTodos
		end)

		for index = 1, #TODOS do
			expect(result[index]).to.equal(nil)
		end
	end)
end

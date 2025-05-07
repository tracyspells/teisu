local types = require("@types/")
local graph = require("@graph/")

type Flec<T> = types.Flec<T>
type Transformer<T> = (old: T) -> T
type EqualityFn<T> = types.EqualityFn<T>

local createNode = graph.createSourceNode
local updateDescendants = graph.updateDescendants
local get_scope = graph.get_scope
local push_child_to_scope = graph.push_child_to_scope

local function flec<T>(initial_value: T, equals: EqualityFn<T>?): Flec<T>
	local node = createNode(initial_value)

	return function(...: any)
		if select("#", ...) == 0 then
			local scope = get_scope()

			if scope then
				push_child_to_scope(scope, node)
			end

			return node.cache:: T
		end

		local target = ...

		if target == graph.NODE_KEY then
			return node :: any
		end

		local old = node.cache :: T
		local new: T

		if typeof(target) == "function" then
			local callback = target :: Transformer<T>
			new = callback(old)
		else
			new = target
		end

		if new ~= old and not (equals ~= nil and equals(old, new)) then
			node.cache = new

			updateDescendants(node)
		end

		return node.cache :: T
	end
end

return flec :: (<T>(initial_value: T, equals: EqualityFn<T>?) -> Flec<T>) & (<T>() -> Flec<T>)

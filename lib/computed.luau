local types = require("@types/")
local graph = require("@graph/")

type Set<T> = types.Set<T>

type Molecule<T> = types.Molecule<T>
type Node<T> = types.Node<T>

local evaluate = graph.evaluate
local createNode = graph.createDerivedNode
local get_scope = graph.get_scope
local new_scope = graph.new_scope
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local push_child_to_scope = graph.push_child_to_scope
local destroy_scope = graph.destroy_scope
local push_cleanup = graph.push_cleanup
local flush_captures = graph.flush_captures
local depend = graph.depend
local try = graph.try

local function computed<T>(callback: () -> T, equals: ((old: T, new: T) -> boolean)?): Molecule<T>
	local node: Node<T>
	local cleaned_up = false

	local owner = get_scope()
	local inner_scope: graph.Scope?

	local function destroy()
		if not cleaned_up then
			cleaned_up = true

			for parent in next, node.parents do
				parent.children[node] = nil
				node.parents[parent] = nil
			end

			if inner_scope then
				destroy_scope(inner_scope)
				inner_scope = nil
			end
		end
	end

	node = createNode(function()
		if inner_scope then
			destroy_scope(inner_scope)
			inner_scope = nil
		end

		local old = node.cache :: T

		local scope = new_scope(owner)
		push_scope(scope)
		local new = try(
			callback, 
			function() pop_scope() end,
			function() destroy_scope(scope) end
		)
		
		inner_scope = scope
		depend(scope, node)
		flush_captures(scope)

		if new ~= old and not (equals ~= nil and equals(old, new)) then
			node.cache = new
		end
	end)

	if owner then
		push_cleanup(owner, destroy, node)
	end

	return function(...: any)
		if select("#", ...) == 0 then
			local scope = get_scope()
			
			if scope then
				if scope.type == "cleanup" and not owner then
					return push_cleanup(scope, destroy, node) :: never
				end

				push_child_to_scope(scope, node)
			end

			if not cleaned_up then
				evaluate(node)
			end

			return node.cache :: T
		end

		local target = ...

		if target ~= graph.NODE_KEY then
			return nil :: never
		end

		return node :: never
	end
end

return computed

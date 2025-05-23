local types = require("@types/")
local graph = require("@graph/")

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
local depend, unparent = graph.depend, graph.unparent
local try = graph.try

local function computed<T>(callback: () -> T, equals: ((old: T, new: T) -> boolean)?): Molecule<T>
	local node: Node<T>
	local cleaned_up = false

	local owner = get_scope()
	local inner_scope: graph.Scope?

	local function destroy()
		if not cleaned_up then
			cleaned_up = true

			unparent(node)

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
		local function runner(): T
			local new_value = callback()

			if scope.effect_captures ~= false then
				return error(`cannot run an effect inside a computed`)
			end

			return new_value
		end

		push_scope(scope)
		local new = try(
			runner, 
			function() pop_scope() end,
			function() destroy_scope(scope) end
		)
		
		inner_scope = scope
		depend(scope, node)
		flush_captures(scope)

		local not_the_same = if new ~= old and not (equals ~= nil and equals(old, new)) then true else false

		if not_the_same then
			node.cache = new
		end

		return not_the_same
	end)
	node.cache = nil :: never

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
			end

			if not cleaned_up then
				evaluate(node)
			end

			if scope then
				push_child_to_scope(scope, node)
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

local types = require("@types/")
local graph = require("@graph/")

type Node<T> = types.Node<T>
type Cleanup = () -> ()

local evaluate = graph.evaluate
local createNode = graph.createEagerNode
local get_scope = graph.get_scope
local new_scope = graph.new_scope
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local push_cleanup = graph.push_cleanup
local destroy_scope = graph.destroy_scope
local depend = graph.depend
local flush_captures = graph.flush_captures
local try = graph.try

local function effect<T>(callback: (dispose: Cleanup, previous_state: T) -> T, initial_state: T): Cleanup
	local node: Node<T>
	local disconnected = false
	
	local owner = get_scope()
	local inner_scope: graph.Scope?

	local function dispose()
		if not disconnected then
			disconnected = true

			for parent in next, node.parents do
				parent.children[node] = nil
				node.parents[parent] = nil
			end
			
			if inner_scope ~= nil then
				destroy_scope(inner_scope)
				inner_scope = nil
			end

			node = nil :: never
		end
	end

	node = createNode(function()
		if disconnected then
			return
		end

		if inner_scope ~= nil then
			destroy_scope(inner_scope)
			inner_scope = nil
		end

		local scope = new_scope(owner)
		
		push_scope(scope)
		local new_value = try(
			callback,
			function() pop_scope() end,
			function() destroy_scope(scope) end,
			dispose,
			node.cache :: T
		)

		if not disconnected then -- `dispose()` can still be called inside the callback
			inner_scope = scope

			local result: any = new_value
			if type(result) == "table" then
				-- create a shallow copy so that functions like `subscribe` 
				-- can work properly
				result = table.clone(result) 
			end

			node.cache = result :: T
			depend(scope, node)
			flush_captures(scope)
		end
	end)

	if owner then
		push_cleanup(owner, dispose, node)
	end

	node.cache = initial_state

	evaluate(node)

	return dispose
end

return effect :: ((callback: () -> ()) -> Cleanup) 
 & ((callback: (dispose: Cleanup) -> ()) -> Cleanup) 
 & (<T>(callback: (dispose: Cleanup, previous_state: T) -> T, initial_state: T) -> Cleanup)

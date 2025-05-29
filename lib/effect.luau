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
local depend, unparent = graph.depend, graph.unparent
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

			unparent(node)
			
			if inner_scope ~= nil then
				destroy_scope(inner_scope)
				inner_scope = nil
			end

			node = nil :: never
		end
	end

	node = createNode(function()
		if disconnected then
			return false
		end

		if inner_scope ~= nil then
			destroy_scope(inner_scope)
			inner_scope = nil
		end

		local scope = new_scope(owner)

		local function runner(...): T
			local new_value = callback(...)

			if scope.effect_captures ~= false then
				return error(`cannot run an effect inside another effect`)
			end

			return new_value
		end
		
		push_scope(scope)
		local new_value = try(
			runner,
			function() pop_scope() end,
			function() destroy_scope(scope) end,
			dispose,
			node.cache
		)

		if disconnected then -- `dispose()` can still be called inside the callback
			return false
		end

		inner_scope = scope
		node.cache = new_value
		depend(scope, node)
		flush_captures(scope)

		return true
	end)

	if owner then
		local new_captures = if owner.effect_captures ~= false then owner.effect_captures else 0
		new_captures += 1
		owner.effect_captures = new_captures
		push_cleanup(owner, dispose, node)
	end

	node.cache = initial_state

	evaluate(node)

	return dispose
end

return effect :: ((callback: () -> ()) -> Cleanup) 
 & ((callback: (dispose: Cleanup) -> ()) -> Cleanup) 
 & (<T>(callback: (dispose: Cleanup, previous_state: T) -> T, initial_state: T) -> Cleanup)

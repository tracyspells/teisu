local types = require("@types/")
local graph = require("@graph/")
local peek = require("@peek/")

type Map<K, V> = types.Map<K, V>
type Node<T> = types.Node<T>
type Molecule<T> = types.Molecule<T>
type UsedAs<T> = types.UsedAs<T>

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

local function show<T, U>(input: UsedAs<T>, component: () -> U, fallback: (() -> U)?): () -> U?
	local node: Node<U>
	local cleaned_up = false
	
	local owner = get_scope()

	local last_scope: graph.Scope?
	local last_input_result: T?

	local function destroy()
		if not cleaned_up then
			cleaned_up = true

			unparent(node)

			last_input_result = nil

			if last_scope then
				destroy_scope(last_scope)
				last_scope = nil
			end
		end
	end
	
	node = createNode(function()
		local scope = new_scope()
		local function runner(): T
			local new_value = peek(input, true)

			if scope.effect_captures ~= false then
				return error(`cannot run an effect inside a computed`)
			end

			return new_value
		end

		push_scope(scope)
		local input_result = try(
			runner, 
			function() pop_scope() end,
			function() destroy_scope(scope) end
		)
		depend(scope, node)
		flush_captures(scope)

		local did_input_actually_change = false
		local ready_to_display_component = false
		local switched_to_fallback_component = false
	
		if last_input_result ~= input_result then
			did_input_actually_change = true
			last_input_result = input_result
		end

		local is_truthy = not not input_result
		if is_truthy and input_result ~= nil then
			ready_to_display_component = true
		elseif fallback ~= nil then
			switched_to_fallback_component = true
		end

		if not switched_to_fallback_component and not ready_to_display_component then
			node.cache = nil :: never
		end

		local callback, create_new_scope = nil, false
		if ready_to_display_component then
			callback = component
		elseif switched_to_fallback_component then
			callback = fallback :: () -> U
		end

		if did_input_actually_change then
			create_new_scope = true
			if last_scope then
				destroy_scope(last_scope)
				last_scope = nil
			end
		end

		if callback ~= nil and create_new_scope then
			local component_scope = new_scope(owner)
			last_scope = component_scope

			push_scope(component_scope)
			local ok, result = pcall(callback)
			pop_scope()

			if not ok then
				error(`error while running show:\n\n{result}`, 0)
			end

			node.cache = result
			flush_captures(component_scope)
		end

		return true
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
			
			return node.cache :: U
		end

		local target = ...

		if target ~= graph.NODE_KEY then
			return nil :: never
		end

		return node :: never
	end
end

local function switch<T, U>(source: UsedAs<T>): (map: Map<T, ((() -> U)?)>) -> () -> U?
	local owner = get_scope()
	local cleaned_up = false

	return function(map)
		local node: Node<U>

		local last_scope: graph.Scope?
		local last_component: (() -> U)?

		local function destroy()
			if not cleaned_up then
				cleaned_up = true

				unparent(node)

				if last_scope then
					destroy_scope(last_scope)
					last_scope = nil
				end
			end
		end

		node = createNode(function()
			local scope = new_scope()
			local function runner(): (() -> U)?
				local new_value = peek(source, true)

				if scope.effect_captures ~= false then
					return error(`cannot run an effect inside a computed`)
				end

				return map[new_value]
			end

			push_scope(scope)
			local component = try(
				runner, 
				function() pop_scope() end,
				function() destroy_scope(scope) end
			)
			depend(scope, node)
			flush_captures(scope)
			
			if component == last_component then
				return false
			end

			if last_scope then
				destroy_scope(last_scope)
				last_scope = nil
			end

			last_component = component

			if component == nil then
				node.cache = nil :: never
				return true
			end

			if type(component) ~= "function" then
				error(`switch: 'map' argument must map a value to a function`, 0)
				return false
			end

			local new_scope = new_scope(owner)
			last_scope = new_scope

			push_scope(new_scope)
			local ok, result = xpcall(component, debug.traceback)
			pop_scope()

			if not ok then
				error(result, 0)
				return false
			end

			node.cache = result
				
			return true
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
				
				return node.cache :: U
			end

			local target = ...

			if target ~= graph.NODE_KEY then
				return nil :: never
			end

			return node :: never
		end
	end
end

return table.freeze {
	show = show,
	switch = switch,
}

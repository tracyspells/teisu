local graph = require("@graph/")
local creation = require("@creation/")
local types = require("@types/")

type Map<K, V> = types.Map<K, V>
type Node<T> = types.Node<T>

local evaluate = graph.evaluate
local createDerivedNode = graph.createDerivedNode
local root = creation.root
local get_root_scope = graph.get_root_scope
local push_to_root_scope = graph.push_to_root_scope
local capturing = graph.capturing

local function show<T, U>(input: () -> boolean?, component: () -> T, fallback: (() -> U)?): () -> (T | U)?
	local node: Node<T>
	local cleaned_up, is_under_root_scope = false, false
	local owner = get_root_scope()
	local destroy_scope: (() -> ())?

	local function destroy()
		if not cleaned_up then
			cleaned_up = true

			for parent in next, node.parents do
				parent.children[node] = nil
			end

			table.clear(node.parents)

			if destroy_scope then
				destroy_scope()
				destroy_scope = nil
			end

			node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = nil :: never
		end
	end

	node = createDerivedNode(function()
		local result: T

		if destroy_scope then
			destroy_scope()
			destroy_scope = nil
		end

		if input() then
			destroy_scope, result = root(function()  
				return component()
			end)
		elseif fallback then
			destroy_scope, result = root(function()  
				return fallback() :: any
			end)
		end

		node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = result
	end)

	if owner then
		is_under_root_scope = true
		push_to_root_scope(owner, node, destroy)
	end

	return function(...: any)
		if select("#", ...) == 0 then
			if capturing.n > 0 then
				local scope = capturing[capturing.n]

				if scope.type == nil then
					scope[node] = true
				elseif scope.type == "cleanup" and not is_under_root_scope then
					table.insert(scope, destroy)
				end
			end

			if not cleaned_up then
				evaluate(node)
			end

			return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: any
		end

		local target = ...

		if target ~= graph.NODE_KEY then
			return nil :: never
		end

		return node :: never
	end
end

local function switch<T, U>(source: () -> T): (map: Map<T, ((() -> U)?)>) -> () -> U?
	local owner = get_root_scope()
	local cleaned_up, is_under_root_scope = false, false

	local destroy_scope: (() -> ())?
	local last_component: (() -> U)?
	local node: Node<U>

	local function destroy()
		if not cleaned_up then
			cleaned_up = true

			for parent in next, node.parents do
				parent.children[node] = nil
			end

			table.clear(node.parents)

			last_component = nil
			
			if destroy_scope then
				destroy_scope()
				destroy_scope = nil
			end

			node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = nil :: never
		end
	end

	return function(map)
		local function update()
			if destroy_scope then
				destroy_scope()
				destroy_scope = nil
			end

			local component = map[source()]

			if component == nil then
				node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = nil :: never
				return
			end

			if typeof(component) ~= "function" then
				return error("map must map a value to a function")
			end

			if component == last_component then
				return
			end

			last_component = component

			local result: any
			destroy_scope, result = root(component)

			node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = result
		end

		node = createDerivedNode(update)

		if owner then
			is_under_root_scope = true
			push_to_root_scope(owner, node, destroy)
		end

		return function(...: any)
			if select("#", ...) == 0 then
				if capturing.n > 0 then
					local scope = capturing[capturing.n]

					if scope.type == nil then
						scope[node] = true
					elseif scope.type == "cleanup" and not is_under_root_scope then
						table.insert(scope, destroy)
					end
				end

				if not cleaned_up then
					evaluate(node)
				end

				return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: U
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

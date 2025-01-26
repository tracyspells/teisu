local graph = require("@graph/")
local computed = require("@computed/")
local peek = require("@peek/")
local creation = require("@creation/")
local types = require("@types/")

type Map<K, V> = types.Map<K, V>
type Node<T> = types.Node<T>

local evaluate = graph.evaluate
local createDerivedNode = graph.createDerivedNode
local root = creation.root
local get_root_scope = graph.get_root_scope
local push_to_root_scope = graph.push_to_root_scope
local remove_from_root_scope = graph.remove_from_root_scope
local capturing = graph.capturing

local function show<T, U>(input: () -> boolean?, component: () -> T, fallback: (() -> U)?): () -> U?
	local node = computed(function()
		return if input() == true then peek(component) elseif fallback then peek(fallback) else nil
	end)

	node()

	return node :: () -> U?
end

local function switch<T, U>(source: () -> T): (map: Map<T, ((() -> U)?)>) -> () -> U?
	local owner = get_root_scope()

	return function(map)
		local destroy_scope: ( () -> () )?
		local last_component: ( () -> U )?
		local node: Node<U>

		local function update()
			local component = map[source()]

			if owner and destroy_scope then
				remove_from_root_scope(owner, destroy_scope)
			end	

			if destroy_scope then
				destroy_scope()
				destroy_scope = nil
			end

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

			local unroot, result: U = root(component)

			if owner then
				push_to_root_scope(owner, unroot, unroot)
			end

			destroy_scope = unroot

			node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = result
		end

		node = createDerivedNode(update)

		return function(...: any)
			if select("#", ...) == 0 then
				if capturing.n > 0 then
					local scope = capturing[capturing.n]
	
					if scope.type == nil then
						scope[node] = true
					end
				end

				evaluate(node)
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

local types = require("@types/")
local graph = require("@graph/")

type Set<T> = types.Set<T>

type Molecule<T> = types.Molecule<T>
type Node<T> = types.Node<T>

local evaluate = graph.evaluate
local createNode = graph.createDerivedNode
local get_root_scope = graph.get_root_scope
local push_to_root_scope = graph.push_to_root_scope
local capturing = graph.capturing

local function computed<T>(callback: () -> T, equals: ((old: T, new: T) -> boolean)?): Molecule<T>
	local node: Node<T>
	local cleaned_up, is_under_root_scope = false, false
	local owner = get_root_scope()

	local function destroy()
		if not cleaned_up then
			cleaned_up = true

			for parent in next, node.parents do
				parent.children[node] = nil
			end

			table.clear(node.parents)
		end
	end

	node = createNode(function()
		local old = node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
		local new = callback()

		if old ~= new and not (equals ~= nil and equals(old, new)) then
			node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = new
		end
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

			return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
		end

		local target = ...

		if target ~= graph.NODE_KEY then
			return nil :: never
		end

		return node :: never
	end
end

return computed

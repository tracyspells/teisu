local types = require("@types/")
local graph = require("@graph/")

type Set<T> = types.Set<T>

type Molecule<T> = types.Molecule<T>
type Node<T> = types.Node<T>

local evaluate = graph.evaluate
local createNode = graph.createDerivedNode
local capturing = graph.capturing

local function computed<T>(callback: () -> T, equals: ((old: T, new: T) -> boolean)?): Molecule<T>
	local node: Node<T>
	node = createNode(function()
		local old = node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
		local new = callback()

		if old ~= new and not (equals ~= nil and equals(old, new)) then
			node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = new
		end
	end)

	return function(...: any)
		if select("#", ...) == 0 then
			if capturing.n > 0 then
				local scope = capturing[capturing.n]

				if scope.type == nil then
					scope[node] = true
				end
			end

			evaluate(node)

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

local types = require("@types/")
local graph = require("@graph/")

type Flec<T> = types.Flec<T>
type Transformer<T> = (old: T) -> T

type EqualityFn<T> = (old: T, new: T) -> boolean

local createNode = graph.createSourceNode
local updateDescendants = graph.updateDescendants
local capturing = graph.capturing

local function flec<T>(initial_value: T, equals: EqualityFn<T>?): Flec<T>
	local node = createNode(initial_value)

	return function(...: any)
		if select("#", ...) == 0 then
			if capturing.n > 0 then
				local scope = capturing[capturing.n]

				if scope.type == nil then
					scope[node] = true
				end
			end

			return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
		end

		local target = ...

		if target == graph.NODE_KEY then
			return node :: any
		end

		local old = node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
		local new: T

		if typeof(target) == "function" then
			local callback = target :: Transformer<T>
			new = callback(old)
		else
			new = target
		end

		if new ~= old and not (equals ~= nil and equals(old, new)) then
			node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = new

			updateDescendants(node)
		end

		return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
	end
end

return flec :: (<T>(initial_value: T, equals: EqualityFn<T>?) -> Flec<T>) & (<T>() -> Flec<T>)

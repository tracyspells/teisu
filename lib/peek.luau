if not game then
	script = require("../test/relative-string")
end

local graph = require(script.Parent.graph)
local types = require(script.Parent.types)

type UsedAs<T> = types.UsedAs<T>

local castToNode = graph.castToReactable
local evaluate = graph.evaluate

local function peek<T>(target: UsedAs<T>): T
	local node = castToNode(target)

	if node ~= nil then
		evaluate(node)

		return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
	end

	return target :: T
end

return peek

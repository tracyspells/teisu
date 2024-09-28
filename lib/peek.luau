local graph = require(script.Parent.graph)
local types = require(script.Parent.types)

type UsedAs<T> = types.UsedAs<T>

local castToReactable = graph.castToReactable

local function peek<T>(target: UsedAs<T>): T
	local reactable = castToReactable(target)

	if reactable == nil then
		return target :: T
	end

	return reactable.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
end

return peek

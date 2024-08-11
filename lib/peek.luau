local types = require(script.Parent.types)

local castToState = require(script.Parent.utils.castToState)
local evaluate = require(script.Parent.graph.evaluate)

type UsedAs<T> = types.UsedAs<T>
type StateObject<T> = types.StateObject<T>

--[=[
	Extracts a value of type T from its input.
	
	@param target The value, computed to peek into.
	@return The value inside.
]=]
local function peek<T>(target: UsedAs<T>): T
	local targetState = castToState(target)

	if targetState ~= nil then
		evaluate(targetState, false)

		return targetState._value
	else
		return target :: T
	end
end

return peek

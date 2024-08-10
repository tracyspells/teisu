local types = require(script.Parent.Parent.types)
local isStateObject = require(script.Parent.isStateObject)

type StateObject<T> = types.Value<T> | types.Computed<T>
type UsedAs<T> = types.UsedAs<T>

local function castToState<T>(target: UsedAs<T>): StateObject<T>?
	if isStateObject(target) then
		return target :: StateObject<T>
	end

	return nil
end

return castToState

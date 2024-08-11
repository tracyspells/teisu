local types = require(script.Parent.Parent.types)
local isStateObject = require(script.Parent.isStateObject)

type Computed<T> = types.Computed<T>
type Value<T> = types.Value<T>
type StateObject<T> = types.Value<T> | types.Computed<T>

type UsedAs<T> = types.UsedAs<T>

local function castToState<T>(target: UsedAs<T>): StateObject<T>?
	if isStateObject(target) == true then
		return target :: StateObject<T>
	end

	return nil
end

local function castToComputed<T>(target: UsedAs<T>): Computed<T>?
	local targetState = castToState(target)

	if targetState ~= nil and targetState.implements.computed == true then
		return targetState :: Computed<T>
	end

	return nil
end

local function castToValue<T>(target: UsedAs<T>): Value<T>?
	local targetState = castToState(target)

	if targetState ~= nil and targetState.implements.value == true then
		return targetState :: Value<T>
	end

	return nil
end

return {
	state = castToState,
	computed = castToComputed,
	value = castToValue,
}

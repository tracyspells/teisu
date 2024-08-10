-- https://github.com/littensy/charm/blob/main/src/sync/patch.luau

local types = require(script.Parent.Parent.types)

type AnyDictionary = types.AnyDictionary
type Array<T> = types.Array<T>

local NONE = { __none = "__none" }


local function isArray(x: Array<any>): boolean
	return #x > 0
end

local function isNone(value: any): boolean
	return type(value) == "table" and value.__none == "__none"
end

local function difference(old: AnyDictionary, new: AnyDictionary): AnyDictionary
	if not old then
		return table.clone(new)
	end

	local result = table.clone(new)

	for key, value in old do
		local other = new[key]

		if value == other then
			result[key] = nil
		elseif other == nil then
			result[key] = NONE
		elseif typeof(value) == "table" and typeof(other) == "table" then
			result[key] = difference(value, other)
		end
	end

	return result
end

local function applyDifference(base: any, difference: any): any
	if isNone(difference) then
		return nil
	elseif typeof(base) ~= "table" or typeof(difference) ~= "table" then
		return difference
	end

	local clone = table.clone(base)
	local isanArray = isArray(base) 

	for key in next, difference do
		if isanArray == true and type(key) == "string" then
			key = tonumber(key) or key
		end

		clone[key] = applyDifference(clone[key], difference[key])
	end

	return clone
end

return {
    delta = difference,
    apply = applyDifference,
	
	NONE = NONE,
}

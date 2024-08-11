--[=[
    Determines if the given object is a state object.

    @param object The object to check.
    @return A boolean.
]=]
local function isState(object: any): boolean
	if typeof(object) ~= "table" then
		return false
	end

	if object.implements == nil then
		return false
	end

	if object.implements.node == nil then
		return false
	end

	if object.implements.value == nil and object.implements.computed == nil then
		return false
	end

	return true
end

return isState

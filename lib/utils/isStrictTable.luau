--[=[
	Determines if the given object is a table (with no existing metatables).

    @param object The object to check.
    @return A boolean.
]=]
local function isStrictTable(object: any): boolean
	if typeof(object) == "table" and getmetatable(object) == nil then
		return true
	end

	return false
end

return isStrictTable

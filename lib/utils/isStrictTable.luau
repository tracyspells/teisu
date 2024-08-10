local function isStrictTable(value: any): boolean
	if typeof(value) == "table" and getmetatable(value) == nil then
		return true
	end

	return false
end

return isStrictTable

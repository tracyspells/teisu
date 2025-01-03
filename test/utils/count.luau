--[=[
	Counts the number of elements in a table.

	@param object The table to count.
	@return The number of elements in the table.
]=]
return function(object: {}): number
	local count = 0
	for _ in next, object do
		count += 1
	end
	return count
end

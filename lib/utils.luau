local types = require(script.Parent.types)

type Molecule<T> = types.Molecule<T>

type Node<T> = types.Node<T>


--[=[
	Counts the number of elements in a table.

	@param object The table to count.
	@return The number of elements in the table.
]=]
local function count(object: {}): number
	local count = 0
	for _ in next, object do
		count += 1
	end
	return count
end

--[=[
	Trigger a garbage collection cycle by allocating a large amount of junk memory
	and then waiting for the next frame.
]=]
local function collect()
	for _ = 1, 1e4 do
		local _ = table.create(1e3)
	end
	task.wait()
end

local function isStrictTable(object: any): boolean
	if typeof(object) == "table" and getmetatable(object) == nil then
		return true
	end

	return false
end

return table.freeze({
	count = count,
	collect = collect,
	isStrictTable = isStrictTable,
})

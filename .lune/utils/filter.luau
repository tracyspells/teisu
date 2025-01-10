local function truthy(...: any)
	return true
end

local function array<T>(array: { T }, predicate: ((value: T, index: number) -> boolean)?): { T }
	local result = {}
	local fn: (value: T, index: number) -> boolean = type(predicate) == "function" and predicate or truthy

	for index, value in ipairs(array) do
		if fn(value, index) == true then
			table.insert(result, value)
		end
	end

	if #result == #array then
		return array
	end

	return result
end

local function dictionary<K, V>(dictionary: { [K]: V }, predicate: ((value: V, key: K) -> boolean)?): { [K]: V }
	local result = {}
	local a_size, b_size = 0, 0
	local fn: (value: V, key: K) -> boolean = if type(predicate) == "function" then predicate else truthy

	for key, value in pairs(dictionary) do
		a_size += 1
		if fn(value, key) then
			result[key] = value
			b_size += 1
		end
	end

	if a_size == b_size then
		return dictionary
	end

	return result
end

return table.freeze({
	array = array,
	dictionary = dictionary,
})

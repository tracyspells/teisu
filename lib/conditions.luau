local types = require("@types/")
local peek = require("@peek/")
local computed = require("@computed/")

type Map<K, V> = types.Map<K, V>
type Node<T> = types.Node<T>
type Molecule<T> = types.Molecule<T>
type UsedAs<T> = types.UsedAs<T>

local function show<T, U>(input: UsedAs<T>, component: () -> U, fallback: (() -> U)?): () -> U?
	return computed(function()
		local input_result = peek(input, true)
		local is_truthy = not not input_result
		local result: U?

		if is_truthy == true and input_result ~= nil then
			result = peek(component :: any)
		elseif fallback ~= nil then
			result = peek(fallback :: any)
		end

		return result
	end)
end

local function switch<T, U>(source: UsedAs<T>): (map: Map<T, ((() -> U)?)>) -> () -> U?
	return function(map)
		return computed(function()
			local key = peek(source, true)
			local component = map[key]
			local result: U?

			if type(component) == "function" then
				result = peek(component :: any)
			end

			return result
		end)
	end
end

return table.freeze {
	show = show,
	switch = switch,
}

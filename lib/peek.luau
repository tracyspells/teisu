local types = require("./types")
local graph = require("./graph")

type UsedAs<T> = types.UsedAs<T>

local capturing = graph.capturing

local function peek<T>(target: UsedAs<T>): T
	if typeof(target) ~= "function" then
		return target :: T
	end

	if capturing.n == 0 then
		return target()
	end

	local index = capturing.n + 1
	capturing.n = index
	capturing[index] = {}

	local result = target()

	capturing.n = index - 1
	capturing[index] = nil

	return result
end

return peek

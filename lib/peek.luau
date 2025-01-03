local types = require("./types")
local graph = require("./graph")

type UsedAs<T> = types.UsedAs<T>

local capturing = graph.capturing

local function peek<T>(target: UsedAs<T>): T
	if typeof(target)  ~= "function"  then
		return target :: T
	end

	if capturing.index == 0 then
		return target()
	end

	capturing.index += 1
	capturing.stack[capturing.index] = {}

	local result = target()
	
	capturing.stack[capturing.index] = nil
	capturing.index -= 1

	return result
end

return peek

local types = require("@types/")
local graph = require("@graph/")

type UsedAs<T> = types.UsedAs<T>

local capturing = graph.capturing
local new_scope = graph.new_scope
local remove_scope = graph.remove_scope

return function<T>(target: UsedAs<T>, dont_untrack: boolean?): T
	if typeof(target) ~= "function" then
		return target :: T
	end

	if capturing.n == 0 or dont_untrack == true then
		return target()
	end

	local index, scope = new_scope()
	local result = target()
	remove_scope(index)
	table.clear(scope)

	return result
end

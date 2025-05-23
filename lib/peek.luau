local types = require("@types/")
local graph = require("@graph/")

type UsedAs<T> = types.UsedAs<T>

local get_scope = graph.get_scope

return function<T>(target: UsedAs<T>, dont_untrack: boolean?): T
	if typeof(target) ~= "function" then
		return target
	end

	local scope = get_scope()

	if scope == nil or dont_untrack == true then
		return target()
	end

	local captured = scope.captures
	scope.captures = false -- disable dependency tracking
	local result = target()
	scope.captures = captured :: any

	return result
end

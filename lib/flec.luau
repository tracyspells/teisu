local graph = require(script.Parent.graph)
local types = require(script.Parent.types)

type Flec<T> = types.Flec<T>
type Transformer<T> = (old: T) -> T
type Options<T> = {
	equals: (old: T, new: T) -> boolean
}

local createNode = graph.createSourceNode
local updateDescendants = graph.updateDescendants
local capturing = graph.capturing

local NODE_KEY = graph.NODE_KEY

--[=[
	Creates a new flec with the given state.
	
	@param initial_value The initial state.
	@param options Optional configuration.
	@return A new flec.
]=]
local function flec<T>(initial_value: T, options: Options<T>?): Flec<T>
	local node = createNode(initial_value)
	local equals = if options ~= nil and options.equals ~= nil then options.equals else nil
	
	local function flec(...: any)
		if select("#", ...) == 0 then
			for set in next, capturing do
				set[node] = true
			end

			return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
		end
		
		local target = ...
		
		if target == NODE_KEY then
			return node :: any
		end
		
		local old = node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
		local new: T

		if typeof(target) == "function" then
			local callback = target :: Transformer<T>
			new = callback(old)
		else
			new = target
		end

		if old ~= new and not (equals ~= nil and equals(old, new)) then
			node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = new

			updateDescendants(node)
		end
		
		return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
	end
	
	return flec
end

return flec :: (<T>(initial_value: T, options: Options<T>?) -> Flec<T>) & (<T>() -> Flec<T>)

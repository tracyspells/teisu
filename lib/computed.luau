local graph = require(script.Parent.graph)
local types = require(script.Parent.types)

type Set<T> = types.Set<T>

type Molecule<T> = types.Molecule<T>
type Node<T> = types.Node<T>

type Options<T> = {
	equals: (old: T, new: T) -> boolean
}

local establishBonds = graph.establishBonds
local evaluate = graph.evaluate
local createNode = graph.createDerivedNode
local capturing = graph.capturing

local NODE_KEY = graph.NODE_KEY

local function computed<T>(callback: () -> T, options: Options<T>?): Molecule<T>
	local equals = if options ~= nil and options.equals ~= nil then options.equals else nil

	local node
	node = createNode(function()
		local dependencies: Set<Node<any>> = {}
		capturing[dependencies] = {}

		local old = node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
		local new = callback()

		capturing[dependencies] = nil

		for dependency in next, dependencies do
			establishBonds(node, dependency)
		end

		if old ~= new and not (equals ~= nil and equals(old, new)) then
			node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = new
		end

		return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value
	end)
	
	return function(...: any)
		if select("#", ...) == 0 then
			for set in next, capturing do
				set[node] = true
			end

			evaluate(node)

			return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
		end
		
		local argument = ...
		
		if argument == NODE_KEY then
			return node :: any
		end
	
		return nil :: never
	end
end

return computed

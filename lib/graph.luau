local types = require(script.Parent.types)
local flags = require(script.Parent.flags)

type Array<T> = types.Array<T>
type Set<T> = types.Set<T>

type Node<T> = types.Node<T>
type NodeState = types.NodeState
type NodeNonCleanState = types.NodeNonCleanState

local capturing: Set<Set<Node<any>>> = {}

local NODE_KEY = newproxy()

local function createSourceNode<T>(initialState: T): Node<T>
	return {
		parents = table.freeze({}),
		children = {},
		state = "clean",
		createdAt = os.clock(),
		___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = initialState,
		effect = false,
	}
end

local function createDerivedNode<T>(effect: () -> T): Node<T>
	return {
		parents = {},
		children = {},
		state = "dirty",
		createdAt = os.clock(),
		___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = false,
		effect = effect,
	}
end

local function createEagerNode<T>(effect: () -> ()): Node<T>
	return {
		parents = {},
		children = table.freeze({}),
		state = "dirty",
		createdAt = os.clock(),
		___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = false,
		effect = effect,
		eager = true,
	}
end

local function establishBonds(child: Node<any>, parent: Node<any>)
	if table.isfrozen(parent.children) or table.isfrozen(child.parents) then
		--TODO: make a cool error here

		return
	end

	child.parents[parent] = true
	parent.children[child] = true
end

local function castToNode<T>(target: T): Node<T>?
	if typeof(target) ~= "table" or target.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value == nil then
		return nil
	end

	return target :: any
end

local function castToReactable<T>(target: T): Node<T>?
	if typeof(target) ~= "function" then
		return nil
	end

	local fn: (...any) -> Node<T> = target
	local targetNode = castToNode(fn(NODE_KEY))

	if targetNode == nil then
		return nil
	end

	return targetNode :: any
end

local function isSourceNode(value: any): (boolean, Node<any>?)
	local node = castToReactable(value)

	if node == nil then
		return false, nil
	end

	return node.eager == nil and node.effect == false, node
end

local function update<T>(node: Node<T>)
	-- sever ties with this node's parents
	for parent in node.parents do
		parent.children[node] = nil
		node.parents[parent] = nil
	end

	local effect = node.effect :: (() -> ()) | false
	if effect ~= false then
		local ok, result: string? = xpcall(effect :: () -> (), debug.traceback)

		if not ok then
			error(result)
		end
	end

	for child in node.children do
		child.state = "dirty"
	end
end

local function updateIfNecessary<T>(node: Node<T>)
	if node.state == "check" then
		for parent in node.parents do
			updateIfNecessary(parent)

			local currentState: NodeNonCleanState = node.state

			if currentState == "dirty" then
				break
			end
		end
	end

	if node.state == "dirty" then
		update(node)
	end

	node.state = "clean"
end

local function updateDescendants(sourceNode: Node<any>)
	if flags.batching then
		if not sourceNode.isPartOfBatch then
			for set in next, capturing do
				local batched = set["___batch" :: any]

				if batched == nil then
					continue
				end

				set[sourceNode] = true
				sourceNode.isPartOfBatch = true
			end
		end

		return
	end

	local queue: Array<Set<Node<any>>> = {}

	local eagerNodes: Array<Node<any>> = {}
	local eagerNodesSeen: Array<number> = {}

	table.insert(queue, sourceNode.children)

	while #queue > 0 do
		local children = table.remove(queue, 1)

		if children == nil then
			continue
		end

		for child in children do
			local isDirectChild = child.parents[sourceNode] == true
			local isChildEager = child.eager ~= nil and true or false

			child.state = if isDirectChild then "dirty" else "check"

			if isChildEager and table.find(eagerNodesSeen, child.createdAt) == nil then
				table.insert(eagerNodes, child)
				table.insert(eagerNodesSeen, child.createdAt)

				-- eager nodes don't have any children
				-- so it's fine to skip them here
				continue
			end

			table.insert(queue, child.children)
		end
	end

	table.clear(eagerNodesSeen)

	table.sort(eagerNodes, function(a, b)
		return a.createdAt < b.createdAt
	end)

	for _, node in eagerNodes do
		updateIfNecessary(node)
	end
end

return table.freeze({
	NODE_KEY = NODE_KEY,
	capturing = capturing,

	createSourceNode = createSourceNode,
	isSourceNode = isSourceNode,
	createDerivedNode = createDerivedNode,
	createEagerNode = createEagerNode,
	evaluate = updateIfNecessary,
	castToReactable = castToReactable,
	updateDescendants = updateDescendants,
	establishBonds = establishBonds,
})

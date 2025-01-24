local types = require("@types/")
local flags = require("@flags/")

type Map<K, V> = types.Map<K, V>
type Array<T> = types.Array<T>
type Set<T> = types.Set<T>

type Node<T> = types.Node<T>
type NodeState = types.NodeState
type NodeNonCleanState = types.NodeNonCleanState

export type Scope = Map<any, any>

local batched: Set<Node<any>> = {}
local capturing = { n = 0 } :: { [number]: Scope, n: number }

local NODE_KEY = newproxy()

local function new_scope(): (number, Scope)
	local scope = {}

	local index = capturing.n + 1
	capturing.n = index
	capturing[index] = scope

	return index, scope
end

local function push_scope(scope: Scope): number
	local n = capturing.n + 1
	capturing.n = n
	capturing[n] = scope

	return n
end

local function remove_scope(index: number)
	local n = index - 1
	capturing.n = n
	capturing[index] = nil
end

local function get_scope(index: number?): Scope?
	return capturing[index or capturing.n]
end

local function createSourceNode<T>(initialState: T): Node<T>
	return {
		parents = table.freeze {},
		children = {},
		state = "clean",
		createdAt = os.clock(),
		___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = initialState,
		nickname = "flec",
		effect = false,
	}
end

local function createDerivedNode<T>(effect: () -> ()): Node<T>
	return {
		parents = {},
		children = {},
		state = "dirty",
		createdAt = os.clock(),
		___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = false,
		nickname = "computed",
		effect = effect,
	}
end

local function createEagerNode<T>(effect: (...any) -> ()): Node<T>
	return {
		parents = {},
		children = table.freeze {},
		state = "dirty",
		createdAt = os.clock(),
		___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = false,
		effect = effect,
		nickname = "effect",
		eager = true,
	}
end

local function establishBonds(child: Node<any>, parent: Node<any>)
	if table.isfrozen(parent.children) or table.isfrozen(child.parents) then
		error(`{parent.nickname} cannot depend on {child.nickname}`)
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

	return castToNode((target :: (...any) -> Node<T>)(NODE_KEY)) :: any
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
	for parent in next, node.parents do
		parent.children[node] = nil
		node.parents[parent] = nil
	end

	local effect = node.effect :: (() -> ()) | false
	if effect ~= false then
		local parents: Set<Node<any>> = {}
		local index = push_scope(parents)

		local ok, message: string? = xpcall(effect :: () -> (), debug.traceback)

		remove_scope(index)

		if not ok then
			error(message)
		end

		for parent in next, parents do
			establishBonds(node, parent)
		end
	end

	for child in next, node.children do
		child.state = "dirty"
	end
end

local function updateIfNecessary<T>(node: Node<T>)
	if node.state == "check" then
		for parent in next, node.parents do
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
			batched[sourceNode] = true
			sourceNode.isPartOfBatch = true
		end

		return
	end

	if next(sourceNode.children) == nil then
		return
	end

	local queue: Array<Set<Node<any>>> = { sourceNode.children }

	local eagerNodes: Array<Node<any>> = {}
	local eagerNodesSeen: Map<Node<any>, number> = {}

	repeat
		local children = table.remove(queue, 1) :: Set<Node<any>>

		for child in next, children do
			local isDirectChild = child.parents[sourceNode] == true
			local isChildEager = child.eager ~= nil and true or false
			local isEmpty = next(child.children) == nil

			child.state = if isDirectChild then "dirty" else "check"

			if isChildEager and eagerNodesSeen[child] == nil then
				table.insert(eagerNodes, child)
				eagerNodesSeen[child] = child.createdAt
			end

			if not isEmpty then
				table.insert(queue, child.children)
			end
		end
	until #queue <= 0 or children == nil

	table.clear(eagerNodesSeen)

	for _, node in next, eagerNodes do
		updateIfNecessary(node)
	end
end

return table.freeze {
	NODE_KEY = NODE_KEY,
	capturing = capturing,
	batched = batched,

	push_scope = push_scope,
	new_scope = new_scope,
	remove_scope = remove_scope,
	get_scope = get_scope,

	createSourceNode = createSourceNode,
	isSourceNode = isSourceNode,
	createDerivedNode = createDerivedNode,
	createEagerNode = createEagerNode,
	evaluate = updateIfNecessary,
	castToReactable = castToReactable,
	updateDescendants = updateDescendants,
	establishBonds = establishBonds,
}

local types = require("@types/")
local flags = require("@flags/")

type Map<K, V> = types.Map<K, V>
type Array<T> = types.Array<T>
type Set<T> = types.Set<T>

type Cleanup = types.Cleanup

type Node<T> = types.Node<T>
type NodeState = types.NodeState
type NodeNonCleanState = types.NodeNonCleanState

type Task = types.Task

export type Scope = {
	cleanups: { Task | Cleanup } | false, -- { object, cleanup_function }
	captures: { [Node<any>]: boolean } | false,
	effect_captures: number | false,
	owned: { Scope } | false,
    owner: Scope | false,
	type: ("cleanup")?,
}

local batched: { [Node<any>]: boolean } = {}
local capturing = { n = 0 } :: { [number]: Scope, n: number }

local NODE_KEY = newproxy()

local function find_and_swap_pop<T>(t: { T }, v: T)
    local i = table.find(t, v) :: number
    local n = #t
    t[i] = t[n]
    t[n] = nil
end

local function push_scope(scope: Scope): number
	local n = capturing.n + 1
	capturing.n = n
	capturing[n] = scope

	return n
end

local function pop_scope(index: number?)
	if capturing.n == 0 then return end

	local n_now = index or capturing.n

	if capturing[n_now] == nil then return end

	local n_new = n_now - 1
	capturing.n = n_new
	capturing[n_now] = nil
end

local function get_scope(index: number?): Scope?
	return capturing[index or capturing.n]
end

local function new_scope(owner: Scope?, type: ("cleanup")?): Scope
	local scope: Scope = {
		cleanups = false,
		captures = false,
		effect_captures = false,
		owned = false,
		owner = if owner ~= nil then owner else false,
		type = type,
	}

	if owner ~= nil then
		if owner.owned ~= false then
			table.insert(owner.owned, scope)
		else
			owner.owned = { scope }
		end
	end

	return scope
end

local function push_cleanup(scope: Scope, cleanup: Cleanup, object: any)
	if scope.cleanups then
		table.insert(scope.cleanups, object)
		table.insert(scope.cleanups, cleanup)
	else
		scope.cleanups = { object, cleanup }
	end
end

local function flush_cleanups(scope: Scope)
	if not scope.cleanups then
		return
	end

	local list = scope.cleanups
	local len = #list
	
	if len == 2 then
		local cleanup = list[2] :: Cleanup
		cleanup()
	elseif len > 2 then
		local already_cleaned_up: { [Task]: boolean } = {}

		for i = len, 1, -2 do
			local cleanup = list[i] :: Cleanup
			local object = list[i - 1] :: Task
			
			if not already_cleaned_up[object] then
				already_cleaned_up[object] = true
				cleanup()
			end
		end
	end

	table.clear(scope.cleanups)
	scope.cleanups = false
end

local function flush_captures(scope: Scope)
	if scope.captures ~= false then
		table.clear(scope.captures)
		scope.captures = false
	end
end

local function push_child_to_scope<T>(scope: Scope, node: Node<T>)
	if scope.type == "cleanup" then return end
	
	if scope.captures ~= false then
		scope.captures[node] = true
	else
		local captures = {}
		captures[node] = true
		scope.captures = captures
	end
end

local function destroy_scope(scope: Scope)
	if scope.effect_captures ~= false then
		scope.effect_captures = false
	end

	flush_captures(scope)
	flush_cleanups(scope)
	
	if scope.owner ~= false then
		find_and_swap_pop(scope.owner.owned :: { Scope }, scope)
		scope.owner = false
	end

	if scope.owned ~= false then
		local owned = scope.owned

		while owned[1] do destroy_scope(owned[1]) end
	end
end

local function createSourceNode<T>(initialState: T): Node<T>
	return {
		parents = table.freeze {},
		children = {},
		state = "clean",
		createdAt = os.clock(),
		cache = initialState,
		nickname = "flec",
		effect = false,
	}
end

local function createDerivedNode<T>(effect: () -> boolean): Node<T>
	return {
		parents = {},
		children = {},
		state = "dirty",
		createdAt = os.clock(),
		cache = false,
		nickname = "computed",
		effect = effect,
	}
end

local function createEagerNode<T>(effect: (...any) -> boolean): Node<T>
	return {
		parents = {},
		children = table.freeze {},
		state = "dirty",
		createdAt = os.clock(),
		cache = false,
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

local function depend<T>(scope: Scope, node: Node<T>)
	if scope.captures == false or node == nil then
		return
	end

	for parent in next, scope.captures do
		establishBonds(node, parent)
	end
end

local function unparent<T>(node: Node<T>)
	for parent in node.parents do
		parent.children[node] = nil
		node.parents[parent] = nil
	end
end

local function castToNode<T>(target: T): Node<T>?
	if typeof(target) ~= "table" or target.cache == nil then
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

local function try<T..., U...>(
	callback: (T...) -> U...,
	finally: (() -> ())?,
	on_error: (() -> ())?,
	...: T...
): U...
	if flags.strict then
		local thread = coroutine.create(callback)
		local result = { coroutine.resume(thread, ...) }

		if finally then
			finally()
		end

		if coroutine.status(thread) == "suspended" then
			local source: string, line: number, name: string = debug.info(callback, "sln")
			coroutine.close(thread)

			if on_error ~= nil then
				on_error()
			end
			
			error(
				"Cannot yield inside a reactive function. Consider wrapping this code in a Promise, task.spawn, or task.defer instead."
					.. `\nFunction defined at: {source}:{line}`
					.. if name == "" then "" else ` function {name}`
			)
		elseif not result[1] then
			local source: string, line: number, name: string = debug.info(callback, "sln")

			if on_error ~= nil then
				on_error()
			end

			error(
				"An error occurred while running an reactive function"
					.. `\nFunction defined at: {source}:{line}`
					.. (if name == "" then "" else ` function {name}`)
					.. `\nError: {result[2]}`
			)
		end

		return unpack(result :: any, 2)
	else
		local result = { pcall(callback, ...) }

		if finally then
			finally()
		end

		if not result[1] then
			if on_error ~= nil then
				on_error()
			end

			error(result[2])
		end

		return unpack(result :: any, 2)
	end
end

local function update<T>(node: Node<T>)
	unparent(node)
	
	local effect = node.effect :: (() -> boolean) | false
	if type(effect) == "function" then
		local meaningfully_changed = effect()

		if node.eager == nil and meaningfully_changed == true then
			for child in node.children do
				child.state = "dirty"
			end
		end
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
	local is_batching = flags.batching == true

	if sourceNode.isPartOfBatch then
		sourceNode.isPartOfBatch = false
	end

	if is_batching and sourceNode.isPartOfBatch then
		return
	end

	if next(sourceNode.children) == nil then
		return
	end

	local queue: Array<Set<Node<any>>> = { sourceNode.children }

	local numOfEagerNodes = 0
	local eagerNodes: Set<Node<any>> = if is_batching then batched else {}

	if is_batching and not sourceNode.isPartOfBatch then
		sourceNode.isPartOfBatch = true
	end

	repeat
		local children = table.remove(queue, 1) :: Set<Node<any>>

		for child in children do
			local isDirectChild = child.parents[sourceNode] == true
			local isChildEager = child.eager == true
			local isEmpty = next(child.children) == nil
			
			child.state = if isDirectChild then "dirty" else "check"

			if isChildEager and eagerNodes[child] == nil then
				if not is_batching then
					numOfEagerNodes += 1
				end

				eagerNodes[child] = true
			end

			if not isEmpty and not isChildEager then
				table.insert(queue, child.children)
			end

			if isChildEager and isDirectChild then
				unparent(child)
			end
		end
	until #queue <= 0

	if numOfEagerNodes <= 0 then return end

	for node in eagerNodes do
		updateIfNecessary(node)
	end
end

return table.freeze {
	NODE_KEY = NODE_KEY,
	batched = batched,

	try = try,
	
	push_scope = push_scope,
	new_scope = new_scope,
	pop_scope = pop_scope,
	get_scope = get_scope,
	destroy_scope = destroy_scope,
	push_child_to_scope = push_child_to_scope,
	push_cleanup = push_cleanup,
	flush_cleanups = flush_cleanups,
	flush_captures = flush_captures,

	createSourceNode = createSourceNode,
	createDerivedNode = createDerivedNode,
	createEagerNode = createEagerNode,
	evaluate = updateIfNecessary,
	castToReactable = castToReactable,
	updateDescendants = updateDescendants,
	establishBonds = establishBonds,
	depend = depend,
	unparent = unparent,
}

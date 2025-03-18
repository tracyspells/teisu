local types = require("@types/")
local spring = require("@spring/")
local action = require("@action/")
local graph = require("@graph/")
local effect = require("@effect/")
local cleanup = require("@cleanup/")

type Map<K, V> = types.Map<K, V>
type Array<T> = types.Array<T>
type Set<T> = types.Set<T>

type Node<T> = types.Node<T>
type Molecule<T> = types.Molecule<T>

type Cache = {
	-- event listeners to connect after properties are set
	events: Array<
		string -- 1. event name
		| () -> () -- 2. listener
	>,

	actions: Array<
		(Instance) -> () -- action callbacks
	>,

	-- each nested layer occupies two indexes: 1. table ref 2. nested depth
	-- e.g. { t1 = { t3 = {} }, t2 = {} } -> { t1, 1, t2, 1, t3, 2 }
	nested_stack: { {} | number },
}

local is_spring = spring.is_spring
local is_action = action.is_action
local get_root_scope = graph.get_root_scope
local push_to_root_scope = graph.push_to_root_scope
local evaluate = graph.evaluate

local implicit_effects
do
	local function property(instance: Instance, property: string, source: Molecule<unknown>)
		effect(function()
			(instance :: any)[property] = source()
		end)
	end

	local function parent(instance: Instance, source: Molecule<Instance>)
		effect(function()
			instance.Parent = source()
		end)
	end

	local function children(instance: Instance, source: Molecule<Instance | { Instance }>)
		local node: Node<any>
		local owner = get_root_scope()

		local disconnected = false
		local new_children: Set<Instance>, prev_children: Set<Instance> = {}, {}

		local function process_child(child: Instance | { Instance })
			if type(child) == "userdata" then
				if not new_children[child] then
					new_children[child] = true
				end

				if not prev_children[child] then
					child.Parent = instance
				else
					prev_children[child] = nil
				end
			elseif type(child) == "table" then
				for _, c in next, child do
					process_child(c)
				end
			elseif type(child) == "function" then
				children(instance, child)
			end
		end

		local function dispose()
			if not disconnected then
				disconnected = true
	
				for parent in next, node.parents do
					parent.children[node] = nil
				end
			end
		end

		local function destroy()
			for child in prev_children do
				child.Parent = nil
			end

			table.clear(new_children)
			table.clear(prev_children)
			dispose()
		end

		node = graph.createEagerNode(function()
			if disconnected then
				return
			end

			process_child(source())

			for child in prev_children do
				child.Parent = nil
			end

			table.clear(prev_children)
			prev_children, new_children = new_children, prev_children
		end)

		if owner then
			push_to_root_scope(owner, node, destroy)
		end

		evaluate(node)
	end

	implicit_effects = table.freeze {
		property = property,
		parent = parent,
		children = children,
	}
end

local free_cache: Cache?

local function borrow_cache(): Cache
	if free_cache then
		local cache = free_cache
		free_cache = nil
		return cache
	end

	return {
		events = {},
		actions = {},
		nested_stack = {},
	}
end

local function return_cache(cache: Cache)
	free_cache = cache
end

local function process_properties(props: Map<unknown, unknown>, instance: Instance, cache: Cache, depth: number)
	for key, value in props do
		if key == "Parent" then
			continue
		end

		if type(key) == "string" then
			if type(value) == "function" then
				if typeof((instance :: any)[key]) == "RBXScriptSignal" then
					table.insert(cache.events, key)
					table.insert(cache.events, value :: () -> ())
				else
					implicit_effects.property(instance, key, value :: Molecule<() -> ()>)
				end
			elseif is_spring(value) then
				implicit_effects.property(instance, key, value :: Molecule<() -> ()>)
			else
				(instance :: any)[key] = value -- set property
			end
		elseif typeof(key) == "number" then
			if type(value) == "userdata" then
				(value :: Instance).Parent = instance -- parent child
			elseif is_action(value) then
				table.insert(cache.actions, (value :: any)[1] :: (Instance) -> ())
			elseif type(value) == "function" then
				implicit_effects.children(instance, value :: Molecule<Instance | { Instance }>)
			elseif type(value) == "table" then
				table.insert(cache.nested_stack, value :: {})
				table.insert(cache.nested_stack, depth + 1)
			end
		end
	end
end

return function<T>(instance: T & Instance, props: Map<unknown, unknown>?): T
	if not props then
		error(`attempt to call a constructor returned by new() with no properties.`)
	end

	local parent: unknown = props.Parent

	local cache: Cache = borrow_cache()
	local events, actions = cache.events, cache.actions
	local nested_stack = cache.nested_stack

	local depth = 1
	repeat
		process_properties(props, instance, cache, depth)
		depth = table.remove(nested_stack) :: number
		props = table.remove(nested_stack) :: {}
	until not props

	for i = 1, #events, 2 do
		local event_name, listener = events[i], events[i + 1]
		if event_name == nil or listener == nil then
			continue
		end
		cleanup((instance :: any)[event_name]:Connect(listener) :: RBXScriptConnection)
	end

	for _, callback in next, actions do
		callback(instance)
	end

	if parent then
		if type(parent) == "function" then
			implicit_effects.parent(instance, parent :: Molecule<Instance>)
		else
			instance.Parent = parent :: Instance
		end
	end

	table.clear(events)
	table.clear(actions)
	table.clear(nested_stack)

	return_cache(cache)

	return instance
end

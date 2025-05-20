local typeof = game and typeof or require("@mock/").typeof
local types = require("@types/")
local spring = require("@spring/")
local tween = require("@tween/")
local action = require("@action/")
local graph = require("@graph/")
local effect = require("@effect/")
local subscribe = require("@subscribe/")
local cleanup = require("@cleanup/")
local peek = require("@peek/")

type Map<K, V> = types.Map<K, V>
type Array<T> = types.Array<T>
type Set<T> = types.Set<T>

type Node<T> = types.Node<T>
type Molecule<T> = types.Molecule<T>
type InstanceMolecule = Molecule<Instance | { Instance }>

type Cache = {
	-- event listeners to connect after properties are set
	events: Array<
		string -- 1. event name
		| () -> () -- 2. listener
	>,

	actions: Array<
		(Instance) -> () -- action callbacks
	>,

	parent: unknown, -- what to parent the instance to after running actions

	-- each nested layer occupies two indexes: 1. table ref 2. nested depth
	-- e.g. { t1 = { t3 = {} }, t2 = {} } -> { t1, 1, t2, 1, t3, 2 }
	nested_stack: { {} | number },
}

local is_spring, is_tween = spring.is_spring, tween.is_tween
local is_action = action.is_action
local get_scope = graph.get_scope
local push_cleanup = graph.push_cleanup

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

	local function children(instance: Instance, source: InstanceMolecule)
		local owner = get_scope()
		local new_parented: Set<Instance> = {}
		local old_parented: Set<Instance> = {}

		local new_connections: { [InstanceMolecule]: () -> () } = {}
		local old_connections: { [InstanceMolecule]: () -> () } = {}

		local function update_children()
			old_parented, new_parented = new_parented, old_parented
			old_connections, new_connections = new_connections, old_connections

			local function process_child(child: Instance | { Instance } | () -> Instance | { Instance })
				if typeof(child) == "Instance" then
					local c: Instance = child :: any
					
					new_parented[c] = true

					if old_parented[c] == nil then
						c.Parent = instance -- if child wasn't already parented then parent it
					else
						old_parented[c] = nil -- remove child from cache if it was already in cache
					end
				elseif type(child) == "table" then
					for _, c in child do
						process_child(c)
					end
				elseif type(child) == "function" then
					local value = peek(child)
					if value ~= nil then
						process_child(value)
					end

					local connection = old_connections[child]
					if connection == nil then
						connection = subscribe(child, update_children)
					else
						old_connections[child] = nil
					end

					new_connections[child] = connection
				end
			end

			process_child(source)

			-- unparent any children that aren't present
			for child in next, old_parented do
				child.Parent = nil
			end

			table.clear(old_parented)

			-- cleanup connections
			for _, disconnect in old_connections do
				disconnect()
			end

			table.clear(old_connections)
		end

		local function destroy()
			source = nil :: never
			update_children()
		end

		if owner then
			push_cleanup(owner, destroy, destroy)
		end

		update_children() -- parent children initially
	end

	implicit_effects = table.freeze({
		property = property,
		parent = parent,
		children = children,
	})
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
		parent = nil,
		actions = {},
		nested_stack = {},
	}
end

local function return_cache(cache: Cache)
	free_cache = cache
end

local function process_properties(props: Map<unknown, unknown>, instance: Instance, cache: Cache, depth: number)
	for key, value in props do
		if type(key) == "string" then
			if key == "Parent" then
				cache.parent = value
				continue
			end

			if type(value) == "function" then
				if typeof((instance :: any)[key]) == "RBXScriptSignal" then
					table.insert(cache.events, key)
					table.insert(cache.events, value :: () -> ())
				else
					implicit_effects.property(instance, key, value :: Molecule<() -> ()>)
				end
			elseif is_spring(value) or is_tween(value) then
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

	for _, callback in actions do
		callback(instance)
	end

	local parent = cache.parent
	if parent ~= nil then
		if type(parent) == "function" then
			implicit_effects.parent(instance, parent :: Molecule<Instance>)
		else
			instance.Parent = parent :: Instance
		end
	end

	cache.parent = nil
	table.clear(events)
	table.clear(actions)
	table.clear(nested_stack)

	return_cache(cache)

	return instance
end

local typeof = game and typeof or require("@mock/").typeof
local types = require("@types/")
local graph = require("@graph/")
local peek = require("@peek/")
local flec = require("@flec/")

type Map<K, V> = types.Map<K, V>
type Molecule<T> = types.Molecule<T>
type Flec<T> = types.Flec<T>
type Node<T> = types.Node<T>
type UsedAs<T> = types.UsedAs<T>
type Scope = graph.Scope
type SubObject<K0, V0, K1, V1> = {
	input_key: K0,
	input_value: Flec<V0>,
	get_output: () -> ((K1 | K0)?, V1?),
	destroy: () -> (),
}

local create_derived_node = graph.createDerivedNode
local get_scope = graph.get_scope
local new_scope = graph.new_scope
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local destroy_scope = graph.destroy_scope
local push_cleanup = graph.push_cleanup
local flush_captures = graph.flush_captures
local push_child_to_scope = graph.push_child_to_scope
local evaluate = graph.evaluate
local depend, unparent = graph.depend, graph.unparent
local try = graph.try

local INFINITY = math.huge

local function create_sub_object<K0, V0, K1, V1>(
	owner: graph.Scope,
	input_key: K0,
	input_value: V0,
	mapper: (Molecule<V0>, K0) -> (V1, K1?)
): SubObject<K0, V0, K1, V1>
	local scope = new_scope(owner)
	local value = flec(input_value)
	local instance_cache: { value: Instance, key: (K0 | K1) }

	local object = {}
	object.input_key = input_key
	object.input_value = value
	object.destroy = function() 
		table.clear(object)
		destroy_scope(scope) 
	end
	object.get_output = function(): ((K1 | K0)?, V1?)
		if instance_cache ~= nil then
			return instance_cache.key, instance_cache.value :: any
		end

		push_scope(scope)
		local k = input_key

		local result = { xpcall(mapper, debug.traceback, value, k) } :: { any }
		local success: boolean = result[1]

		pop_scope()
		
		if success == true then
			local output_value: V1? = result[2]
			local output_key: (K1 | K0) = (result[3] :: K0) or k

			if typeof(output_value) == "Instance" and instance_cache == nil then
				local instance: Instance = output_value :: any
				instance_cache = { key = output_key, value = instance }
				push_cleanup(scope, function() instance_cache = nil :: never end, instance)
			end

			return output_key, output_value
		end

		local error_message: string = result[2] :: any
		object.destroy()
		error(error_message)

		return nil, nil
	end

	return object :: any
end

local function mapped<K0, V0, K1, V1>(input: UsedAs<{ [K0]: V0 }>, mapper: (Molecule<V0>, K0) -> (V1, K1?)): Molecule<{ [K1]: V1 }>
	local owner = get_scope()
	local sub_owner = new_scope(owner)

	local node: Node<{ [K1 | K0]: V1 }>
	local sub_objects: { [SubObject<K0, V0, K1, V1>]: boolean } = {}

	local cleaned_up = false
	local destroy = function()
		if cleaned_up then
			return
		end

		cleaned_up = true

		unparent(node)

		table.clear(sub_objects)
		destroy_scope(sub_owner)
	end

	node = create_derived_node(function()
		if node.cache ~= false then
			table.clear(node.cache)
		end

		-- step 1: capture dependencies
		push_scope(sub_owner)
		local input_data: { [K0]: V0 } = try(peek, function()
			pop_scope()
		end, function()
			destroy_scope(sub_owner)
		end, input, true)

		depend(sub_owner, node)
		flush_captures(sub_owner)

		local pending_pairs = table.clone(input_data)

		local new_sub_objects = {}
		--local updated_sub_objects = {} -- for batching
		
		-- step 2: remove and update existing sub objects
		for object in sub_objects do
			local input_key = object.input_key
			local new_input_value = pending_pairs[input_key]
			
			if new_input_value == nil then
				object.destroy()
				sub_objects[object] = nil
			else
				new_sub_objects[object] = true
				pending_pairs[input_key] = nil
				object.input_value(new_input_value)
				--table.insert(updated_sub_objects, { object = object, value = new_input_value })
			end
		end
	
		-- step 3: create new sub objects
		push_scope(sub_owner)
		for key, value in pending_pairs do
			local sub_object = create_sub_object(sub_owner, key, value, mapper)
			new_sub_objects[sub_object] = true
		end
		pop_scope()

		sub_objects = new_sub_objects

		-- step 4: generate results
		local output = node.cache :: { [K1 | K0]: V1 }

		local min_array_index = INFINITY
		local max_array_index = -INFINITY
		local has_holes = false

		for object in new_sub_objects do
			local output_key, output_value = object.get_output()

			if output_key == nil or output_value == nil then
				has_holes = true
				continue
			elseif output[output_key] ~= nil then
				continue
			end

			output[output_key] = output_value

			if typeof(output_key) == "number" then
				local number: number = output_key :: any
				min_array_index = math.min(min_array_index, number)
				max_array_index = math.max(max_array_index, number)
			end
		end

		if has_holes and max_array_index > min_array_index then
			local _output: { [number]: V1 } = output :: any
			local move_to = min_array_index

			for move_from = min_array_index, max_array_index do
				local output_value = _output[move_from]

				if output_value == nil then
					continue
				end

				_output[move_from] = nil
				_output[move_to] = output_value
				move_to += 1
			end
		end

		return true
	end)

	node.cache = {}

	if owner then
		push_cleanup(owner, destroy, node)
	end

	return function(...: any)
		if select("#", ...) == 0 then
			local scope = get_scope()

			if scope then
				if scope.type == "cleanup" and not owner then
					return push_cleanup(scope, destroy, node) :: never
				end
			end

			if not cleaned_up then
				evaluate(node)
			end

			if scope then
				push_child_to_scope(scope, node)
			end

			return node.cache :: { [K1]: V1 }
		end

		local target = ...

		if target ~= graph.NODE_KEY then
			return nil :: never
		end

		return node
	end
end

return mapped

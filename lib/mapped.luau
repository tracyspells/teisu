local typeof = game and typeof or require("@mock/").typeof
local types = require("@types/")
local flags = require("@flags/")
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
	input_value: V0,
	invalidate_input_key: () -> (),
	invalidate_input_value: () -> (),
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
	type: "keys" | "values" | "indexes",
	input_key: K0,
	input_value: V0,
	mapper: (UsedAs<V0>, UsedAs<K0>) -> (V1, K1?)
): SubObject<K0, V0, K1, V1>
	local scope = new_scope(owner)
	local key = flec(input_key)
	local value = flec(input_value)
	local instance_cache: { value: Instance, key: K0 | K1 }
	local has_cleanups: boolean?

	local function get_output_pair()
		if type == "keys" then
			return peek(key), nil :: never
		end

		if type == "indexes" then
			return key, peek(value)
		end

		return peek(key), value
	end

	local object = {}
	object.input_key = input_key
	object.input_value = input_value
	object.invalidate_input_key = function()
		key(object.input_key)
	end
	object.invalidate_input_value = function()
		value(object.input_value)
	end
	object.destroy = function()
		table.clear(object)
		key, value = nil :: never, nil :: never
		destroy_scope(scope)
	end
	object.get_output = function(): ((K1 | K0)?, (V1 | V0)?)
		if instance_cache ~= nil then
			return instance_cache.key, instance_cache.value :: any
		end

		push_scope(scope)
		local k, v = get_output_pair()

		if type == "keys" then
			k, v = v :: any, k
		end

		-- if there were any cleanups scheduled when the computed is first evaluated
		-- we don't want to duplicate them for future evaluations
		local previous_cleanups
		if has_cleanups == true then
			previous_cleanups = scope.cleanups
			scope.cleanups = false
		end

		local result = { xpcall(mapper, debug.traceback, v, k) } :: { any }
		local success: boolean = result[1]

		pop_scope()
		flush_captures(scope)

		if has_cleanups == true and previous_cleanups ~= nil then
			scope.cleanups = previous_cleanups :: any
		end

		if scope.cleanups ~= false then
			has_cleanups = true
		end

		if success == true then
			local output_value: (V1 | V0)? = result[2]
			local output_key: K1 | K0 = result[3]

			if type == "values" and output_key == nil then
				output_key = k :: K0
			elseif type == "indexes" and output_key == nil then
				output_key = input_key
			elseif type == "keys" and typeof(output_value) ~= "Instance" then
				if output_key == nil then
					output_key = output_value :: any
				end

				output_value = object.input_value
			end

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

local function mapped<K0, V0, K1, V1>(
	type: "keys" | "values",
	input: UsedAs<{ [K0]: V0 }>,
	mapper: (V0, K0) -> (V1?, K1?)
): Molecule<{ [K1]: V1 }>
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
		if node.cache == false then
			node.cache = {}
		else
			local copy = table.clone(node.cache)
			table.clear(copy)
			node.cache = copy
		end

		-- step 1: capture dependencies
		push_scope(sub_owner)
		local input_data: { [K0]: V0 } = try(
			peek, 
			function() pop_scope() end, 
			function()destroy_scope(sub_owner) end, 
			input, true
	    )

		depend(sub_owner, node)
		flush_captures(sub_owner)

		local pending_pairs = table.clone(input_data)

		local new_sub_objects = {}
		--local updated_sub_objects = {} -- for batching

		-- step 2: remove and update existing sub objects
		for object in sub_objects do
			local old_key = object.input_key

			if pending_pairs[old_key] == nil then
				sub_objects[object] = nil
				object.destroy()
			else
				local new_key, new_value = old_key, pending_pairs[old_key]

				new_sub_objects[object] = true
				pending_pairs[new_key] = nil

				if type ~= "keys" then
					object.input_value = new_value
					object.invalidate_input_value()
				end

				--table.insert(updated_sub_objects, { object = object, value = new_input_value })
			end
		end

		-- step 3: create new sub objects
		for key, value in pending_pairs do
			local sub_object = create_sub_object(sub_owner, type, key, value, mapper :: any)
			new_sub_objects[sub_object] = true
		end

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
				if flags.strict then
					error(`Teisu.{type}: key conflict`)
				end

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

local function indexes<K0, V0, V1>(input: UsedAs<{ [K0]: V0 }>, mapper: (V0, Molecule<K0>) -> V1): Molecule<{ [K0]: V1 }>
	local owner = get_scope()
	local sub_owner = new_scope(owner)

	local node: Node<{ [K0]: V1 }>

	local old_input_cache: { [V0]: K0 } = {}
	local new_input_cache: { [V0]: K0 } = {}
	local sub_objects: { [V0]: SubObject<K0, V0, nil, V1> } = {}

	local cleaned_up = false
	local destroy = function()
		if cleaned_up then
			return
		end

		cleaned_up = true

		unparent(node)
		table.clear(sub_objects)
		table.clear(old_input_cache)
		table.clear(new_input_cache)
		destroy_scope(sub_owner)
	end

	node = create_derived_node(function()
		if node.cache == false then
			node.cache = {}
		else
			local copy = table.clone(node.cache)
			table.clear(copy)
			node.cache = copy
		end

		-- step 1: capture dependencies
		push_scope(sub_owner)
		local input_data: { [K0]: V0 } = try(
			peek, 
			function() pop_scope() end, 
			function()destroy_scope(sub_owner) end, 
			input, true
		)

		depend(sub_owner, node)
		flush_captures(sub_owner)

		if flags.strict then
            local cache = {}
            for _, v in input_data do
                if cache[v] ~= nil then
                    error(`Teisu.indexes: duplicate table value detected`)
					return false
                end
                cache[v] = true
            end
        end

		-- step 2: create new sub objects and update existing ones
		for k, v in input_data do
			new_input_cache[v] = k

			local other_k = old_input_cache[v]
			
			if other_k == nil then
				local sub_object = create_sub_object(sub_owner, "indexes", k, v, mapper :: any)
				sub_objects[v] = sub_object
			else
				local sub_object = sub_objects[v]

				if other_k ~= k then
					sub_object.input_key = k
					sub_object.invalidate_input_key()
				end

				old_input_cache[v] = nil
			end
		end

		-- step 3: remove old sub objects
		for v in old_input_cache do
			local sub_object = sub_objects[v]
			if sub_object ~= nil then
				sub_objects[v] = nil
				sub_object.destroy()
			end
		end

		table.clear(old_input_cache)
		old_input_cache, new_input_cache = new_input_cache, old_input_cache

		-- step 4: generate results
		local output = node.cache :: { [K0]: V1 }

		for _, object in sub_objects do
			local output_key, output_value = object.get_output()

			if output_key == nil or output_value == nil then
				continue
			elseif output[output_key] ~= nil then
				if flags.strict then
					error(`Teisu.indexes: key conflict`)
				end

				continue
			end

			output[output_key] = output_value
		end

		return true
	end)

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

			return node.cache :: { [K0]: V1 }
		end

		local target = ...

		if target ~= graph.NODE_KEY then
			return nil :: never
		end

		return node
	end
end

local function keys<K0, V0, K1, V1>(input: UsedAs<{ [K0]: V0 }>, mapper: (K0) -> K1): Molecule<{ [K1]: V1 }>
	return mapped("keys", input, mapper :: any)
end

local function values<K0, V0, V1>(input: UsedAs<{ [K0]: V0 }>, mapper: (Molecule<V0>, K0) -> V1): Molecule<{ [K0]: V1 }>
	return mapped("values", input, mapper)
end

return table.freeze({ keys = keys, values = values, indexes = indexes })

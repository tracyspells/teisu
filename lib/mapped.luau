local types = require("@types/")
local graph = require("@graph/")
local creation = require("@creation/")

type Map<K, V> = types.Map<K, V>
type Molecule<T> = types.Molecule<T>
type Flec<T> = types.Flec<T>
type Node<T> = types.Node<T>

type MappedConstructor =
	(<K0, V0, K1, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1)) -> Molecule<{ [K1]: V1 }>)
	& (<K0, V0, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> V1?) -> Molecule<{ [K0]: V1 }>)
	& (<K0, V0, K1, V1>(
		subject: Molecule<{ [K0]: V0 }>,
		mapper: (V0, K0) -> (V1?, K1?)
	) -> Molecule<{ [K1]: V1 }>)

local createNode = graph.createDerivedNode
local get_root_scope = graph.get_root_scope
local push_to_root_scope = graph.push_to_root_scope
local evaluate = graph.evaluate
local root = creation.root
local capturing = graph.capturing

local function mapped<K0, V0, K1, V1>(molecule: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1?)): Molecule<{ [K1]: V1 }>
	local is_under_root_scope = false
	local owner = get_root_scope()

	local node: Node<{ [K1]: V1 }>
	local mapped_cache: {
		[K0]: {
			previous_value: V0,
			output: { key: K1, value: V1 },
			destroy: () -> (),
		},
	} =
		{}

	local cleaned_up = false
	local cleanup = function()
		if cleaned_up then
			return
		end

		cleaned_up = true

		for parent in next, node.parents do
			parent.children[node] = nil
		end

		-- remove deleted values from the cache
		for key, cache in next, mapped_cache do
			if cache and cache.destroy then
				cache.destroy()
			end

			mapped_cache[key] = nil
		end
	end

	node = createNode(function()
		local new_input = molecule()

		-- remove deleted values from the cache
		for key, cache in next, mapped_cache do
			if new_input[key] == nil then
				-- destroy the root scope if it exists
				if cache and cache.destroy then
					cache.destroy()
				end

				mapped_cache[key] = nil
			end
		end

		for key, value in next, new_input do
			local cache = mapped_cache[key]

			if cache == nil then -- track additions
				local destroy, result = root(function()
					local newValue, newKey = mapper(value, key)
					return { newValue or value, newKey or key } :: { K0 | K1 | V0 | V1 }
				end)

				mapped_cache[key] = {
					destroy = destroy,
					previous_value = value,
					output = { key = result[2] :: K1, value = result[1] :: V1 },
				}
			elseif cache.previous_value ~= value then -- track changes
				cache.previous_value = value
				cache.destroy()

				local destroy, result = root(function()
					local newValue, newKey = mapper(value, key)
					return { newValue or value, newKey or key } :: { K0 | K1 | V0 | V1 }
				end)

				cache.destroy = destroy
				cache.output.key = result[2] :: K1
				cache.output.value = result[1] :: V1
			end
		end

		local result = {}

		for _, cache in next, mapped_cache do
			local output = cache.output
			result[output.key] = output.value
		end

		node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = result
	end)

	if owner then
		push_to_root_scope(owner, node, cleanup)
		is_under_root_scope = true
	end

	return function(...: any)
		if select("#", ...) == 0 then
			if capturing.n > 0 then
				local scope = capturing[capturing.n]

				if scope.type == nil then
					scope[node] = true
				elseif scope.type == "cleanup" and not is_under_root_scope then
					table.insert(scope, cleanup)
				end
			end

			if not cleaned_up then
				evaluate(node)
			end

			return node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: { [K1]: V1 }
		end

		local target = ...

		if target ~= graph.NODE_KEY then
			return nil :: never
		end

		return node
	end
end

return mapped :: MappedConstructor

local types = require("@types/")
local graph = require("@graph/")
local effect = require("@effect/")
local peek = require("@peek/")

type Map<K, V> = types.Map<K, V>
type Molecule<T> = types.Molecule<T>
type Flec<T> = types.Flec<T>
type Node<T> = types.Node<T>

type MappedConstructor =
	(<K0, V0, K1, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1)) -> Molecule<{ [K1]: V1 }>)
	& (<K0, V0, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> V1?) -> Molecule<{ [K0]: V1 }>)
	& (<K0, V0, K1, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1?)) -> Molecule<{ [K1]: V1 }>)

local createNode = graph.createSourceNode
local updateDescendants = graph.updateDescendants
local capturing = graph.capturing

local function mapped<K0, V0, K1, V1>(molecule: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1?)): Molecule<{ [K1]: V1 }>
	local node = createNode {} :: Node<{ [K1]: V1 }>

	local previous_items: { [K0]: V0 }?
	local mapped_cache: { [K0]: { K1 | V1 } }?

	local dispose

	local cleaned_up = false
	local cleanup = function()
		if cleaned_up then
			return
		end
		cleaned_up = true

		if previous_items ~= nil then
			table.clear(previous_items)
		end

		if mapped_cache ~= nil then
			table.clear(mapped_cache)
		end

		dispose()
		node = nil :: never
	end

	local is_under_root_scope = false
	if capturing.n > 0 and capturing[capturing.n].type == "root" then
		local scope = capturing[capturing.n]
		if not scope.already_queued[cleanup] then
			is_under_root_scope = true
			scope.already_queued[cleanup] = true
			table.insert(scope, cleanup)
		end
	end

	dispose = effect(function()
		local items = molecule()
		local mapped_items = table.clone(node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: { [K1]: V1 })

		local changes = 0

		-- removed deleted values
		if previous_items ~= nil and mapped_cache ~= nil then
			for key, item in previous_items do
				local new_item = items[key]

				local cache = mapped_cache[key]
				local mapped_key = cache[2] :: K1

				if new_item == nil and mapped_items[mapped_key] ~= nil then
					mapped_items[mapped_key] = nil
					changes += 1
				end
			end
		end

		-- process new or changed values
		local cache: { [K0]: { K1 | V1 } } = {}
		for key, item in items do
			local result = peek(function()
				local newItem, newKey = mapper(item, key)
				return { newItem or item, newKey or key } :: { K0 | K1 | V0 | V1 }
			end)

			local newItem, newKey = result[1] :: V0 | V1, result[2] :: K0 | K1

			cache[key] = { newItem :: V1, newKey :: K1 }

			if mapped_items[newKey :: K1] ~= newItem then
				mapped_items[newKey :: K1] = newItem :: V1
				changes += 1
			end
		end

		if changes > 0 then
			node.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = mapped_items
			updateDescendants(node)
		end

		return function()
			if cleaned_up then
				return
			end
			previous_items, mapped_cache = items, cache
		end
	end)

	return function(...: any)
		if cleaned_up then
			return nil :: never
		end

		if select("#", ...) == 0 then
			if capturing.n > 0 then
				local scope = capturing[capturing.n]

				if scope.type == nil then
					scope[node] = true
				elseif scope.type == "cleanup" and not is_under_root_scope then
					table.insert(scope, cleanup)
				end
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

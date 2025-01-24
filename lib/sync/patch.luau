local types = require("@types/")

type PatchOperation = types.PatchOperation
type Patch<K, V> = types.Patch<K, V>

type NONE = types.NONE

local NONE = { __none = "__none" } :: NONE

local function is_none(v: any): boolean
	return v == NONE
end

local function diff<K, V>(old: { [K]: V }, new: { [K]: V }): { Patch<K, V> }?
	if old == new then
		return
	end

	local output: { Patch<K, V> } = {}

	for key, prev_value in next, old do
		local curr_value = new[key]

		if curr_value == nil then
			table.insert(output, {
				op = "remove",
				path = { key },
				value = NONE,
			})

			continue
		end

		if typeof(prev_value) == "table" and typeof(curr_value) == "table" then
			local subpatches = diff(prev_value, curr_value)

			if subpatches == nil then
				continue
			end

			for _, patch in subpatches do
				table.insert(output, {
					op = patch.op :: any,
					path = { key, table.unpack(patch.path) },
					value = patch.value,
				})
			end

			continue
		end

		if prev_value ~= curr_value then
			table.insert(output, {
				op = "replace",
				path = { key },
				value = curr_value,
			})
		end
	end

	for key, curr_value in next, new do
		local prev_value = old[key]
		if prev_value == nil then
			table.insert(output, {
				op = "add",
				path = { key },
				value = curr_value,
			})
		end
	end

	return output
end

local function traverse(tbl: { [any]: any }, path: { any }, depth: number, op: PatchOperation, set_to: any)
	if depth > #path then
		depth = #path
	end

	local key = path[depth]
	local value = tbl[key]

	if typeof(value) == "table" then
		return traverse(value, path, depth + 1, op, set_to)
	end

	if (op == "add" and value == nil) or (op == "replace" and value ~= nil) then
		tbl[key] = set_to
	elseif op == "remove" and value ~= nil then
		tbl[key] = nil
	end
end

local function apply<K, V>(state: { [K]: V }, patches: { Patch<K, V> })
	local next_state = table.clone(state)

	for _, info in patches do
		traverse(next_state, info.path, 1, info.op, info.value)
	end

	return next_state
end

return table.freeze {
	diff = diff,
	apply = apply,
	is_none = is_none,
}

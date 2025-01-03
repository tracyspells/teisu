local types = require("./types")
local graph = require("./graph")
local flags = require("./flags")

type Set<T> = types.Set<T>

type Node = types.Node<any>

local updateDescendants = graph.updateDescendants
local batched = graph.batched

return function(callback: () -> ())
	if flags.batching then
		return callback()
	end

	flags.batching = true

	local ok, message: string? = xpcall(callback, debug.traceback)

	flags.batching = false

	local results = table.clone(batched)
	table.clear(batched)

	if not ok then
		error(`error occured while batching updates: \n{message}`)
	end

	local dependency: Node? = nil

	for node in next, results do
		local isSourceNode = node.eager == nil and node.effect == false

		node.isPartOfBatch = nil

		if dependency == nil and isSourceNode then
			dependency = node
		end
	end

	-- we only need one dependency to update its descendants
	-- this solves the issue of computeds/effects having more than one dependency
	-- being updated each time after a batch call completes
	if dependency ~= nil then
		updateDescendants(dependency)
	end
end

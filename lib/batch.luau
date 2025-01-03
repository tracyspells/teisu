local types = require("./types")
local graph = require("./graph")
local flags = require("./flags")

type Set<T> = types.Set<T>

type Node = types.Node<any>

local updateDescendants = graph.updateDescendants
local batched = graph.batched

--[=[
	Runs the given callback and schedules listeners to be notified
	only once after the callback has completed. Useful for batching 
	multiple flec changes.

	@param callback The function to run.
]=]
local function batch(callback: () -> ())
	if flags.batching then
		return callback()
	end

	flags.batching = true

	local ok, message: string? = xpcall(callback, debug.traceback)
	
	flags.batching = false

	if not ok then
		table.clear(batched)
		error(`error occured while batching updates: \n{message}`)
	end

	local dependency: Node? = nil

	for node in next, batched do
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
		table.clear(batched)
		updateDescendants(dependency)
	end
end

return batch

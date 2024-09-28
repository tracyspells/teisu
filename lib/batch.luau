local types = require(script.Parent.types)
local graph = require(script.Parent.graph)
local flags = require(script.Parent.flags)

type Array<T> = types.Array<T>
type Set<T> = types.Set<T>

type Node = types.Node<any>

local updateDescendants = graph.updateDescendants
local capturing = graph.capturing

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

	local key = "___batch"
	local dependencies: Set<Node> = { [key :: any] = true }
	local dependency: Node? = nil

	capturing[dependencies] = true
	flags.batching = true

	local ok, message: string? = pcall(callback)

	flags.batching = false

	capturing[dependencies] = nil
	dependencies[key :: any] = nil

	if not ok then
		error(`error occured while batching updates: \n{message}`)
	end

	for node in next, dependencies do
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
		table.clear(dependencies)
		updateDescendants(dependency)
	end
end

return batch

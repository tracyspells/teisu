local types = require("@types/")
local graph = require("@graph/")
local flags = require("@flags/")

type Set<T> = types.Set<T>
type Map<K, V> = types.Map<K, V>
type Array<T> = types.Array<T>

type Node = types.Node<any>

local evaluate = graph.evaluate
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

	local queue: Array<{ sourceNode: Node, children: Set<Node> }> = {}

	local eagerNodes: Array<Node> = {}
	local eagerNodesSeen: Map<Node, number> = {}

	-- this is pretty much a repeat of `graph.updateDescendants`, but on
	-- a much larger scale

	for node in next, results do
		local isSourceNode = node.eager == nil and node.effect == false

		if not isSourceNode then
			continue
		end

		node.isPartOfBatch = nil

		table.insert(queue, { sourceNode = node, children = node.children })
	end

	repeat
		local entry = table.remove(queue, 1) :: { sourceNode: Node, children: Set<Node> }?

		if entry then
			local source_node = entry.sourceNode

			for child in next, entry.children do
				local isDirectChild = child.parents[source_node] == true
				local isChildEager = child.eager ~= nil and true or false
				local isEmpty = next(child.children) == nil

				child.state = if isDirectChild then "dirty" else "check"

				if isChildEager and eagerNodesSeen[child] == nil then
					table.insert(eagerNodes, child)
					eagerNodesSeen[child] = child.createdAt
				end

				if not isEmpty then
					table.insert(queue, { sourceNode = source_node, children = child.children })
				end
			end
		end
	until #queue <= 0

	table.clear(eagerNodesSeen)

	for _, node in eagerNodes do
		evaluate(node)
	end

	table.clear(eagerNodes)
end

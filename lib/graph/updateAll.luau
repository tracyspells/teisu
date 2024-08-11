local types = require(script.Parent.Parent.types)
local evaluate = require(script.Parent.evaluate)
local flags = require(script.Parent.flags)

type Node = types.Node
type Array<T> = types.Array<T>

local TERMINATION_TIME = 1 -- in seconds
local TERMINATION_TIME_MULTIPLIER = 1

local function updateAll(node: Node)
	if flags.batch then
		return
	end

	if node.state == "busy" then
		error("infinite loop", 0)

		return
	end

	local isAMeaningfulChange = evaluate(node, true)

	if not isAMeaningfulChange then
		return
	end

	local searchInNow: Array<Node> = {}
	local searchInNext: Array<Node> = {}
	local invalidatedNodes: Array<Node> = {}

	local terminateBy = os.clock() + TERMINATION_TIME * TERMINATION_TIME_MULTIPLIER

	table.insert(searchInNow, node)
	repeat
		if os.clock() > terminateBy then
			error("infinite loop", 0)

			return
		end

		local done = true

		for _, targetNode in searchInNow do
			for child in targetNode.children do
				if child.state == "clean" then
					done = false

					table.insert(searchInNext, child)
					table.insert(invalidatedNodes, child)
				elseif child.state == "busy" then
					error("infinite loop", 0)

					return
				end
			end
		end

		searchInNow, searchInNext = searchInNext, searchInNow
		table.clear(searchInNext)
	until done

	local eagerNodes: Array<Node> = {}

	for _, invalidNode in invalidatedNodes do
		invalidNode.state = "dirty"
		if invalidNode.timeliness == "eager" then
			table.insert(eagerNodes, invalidNode)
		end
	end

	table.sort(eagerNodes, function(a, b)
		return a.createdAt < b.createdAt
	end)

	for _, eagerNode in eagerNodes do
		evaluate(eagerNode, false)
	end
end

return updateAll

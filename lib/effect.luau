local graph = require(script.Parent.graph)
local types = require(script.Parent.types)

type Set<T> = types.Set<T>

type Molecule<T> = types.Molecule<T>
type Node<T> = types.Node<T>

type Cleanup = () -> ()

local establishBonds = graph.establishBonds
local evaluate = graph.evaluate
local createNode = graph.createEagerNode
local capturing = graph.capturing

local function effect(callback: () -> Cleanup?): Cleanup
	local node: Node<any>
	local cleanup: Cleanup?

	local gottenCleanupOnce = false
	local disconnected = false

	local function dispose()
		if not disconnected then
			disconnected = true

			for parent in node.parents do
				parent.children[node] = nil
			end

			if cleanup then
				cleanup()
			end
		end
	end

	node = createNode(function()
		if disconnected then
			return
		end

		local dependencies: Set<Node<any>> = {}
		capturing[dependencies] = {}

		if gottenCleanupOnce and cleanup then
			cleanup()
		end

		cleanup = callback()
		capturing[dependencies] = nil

		for dependency in next, dependencies do
			establishBonds(node, dependency)
		end

		if cleanup and not gottenCleanupOnce then
			gottenCleanupOnce = true
		end
	end)

	evaluate(node)

	return dispose
end

return effect :: ((callback: () -> ()) -> Cleanup) & ((callback: () -> Cleanup) -> Cleanup)

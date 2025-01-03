local types = require("./types")
local graph = require("./graph")

type Set<T> = types.Set<T>

type Molecule<T> = types.Molecule<T>
type Node<T> = types.Node<T>

type Cleanup = () -> ()

local evaluate = graph.evaluate
local createNode = graph.createEagerNode

local function effect(callback: () -> Cleanup?): Cleanup
	local node: Node<any>
	local cleanup: Cleanup?

	local gottenCleanupOnce = false
	local disconnected = false

	local function dispose()
		if not disconnected then
			disconnected = true

			for parent in next, node.parents do
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

		if gottenCleanupOnce and cleanup then
			cleanup()
		end

		cleanup = callback()

		if cleanup and not gottenCleanupOnce then
			gottenCleanupOnce = true
		end
	end)

	evaluate(node)

	return dispose
end

return effect :: ((callback: () -> ()) -> Cleanup) & ((callback: () -> Cleanup) -> Cleanup)

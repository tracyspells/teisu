local types = require("@types/")
local graph = require("@graph/")
local peek = require("@peek/")

type Set<T> = types.Set<T>

type Molecule<T> = types.Molecule<T>
type Node<T> = types.Node<T>

type Cleanup = () -> ()

local evaluate = graph.evaluate
local createNode = graph.createEagerNode

local function effect(callback: (dispose: Cleanup, on_change: (Cleanup) -> ()) -> ()): Cleanup
	local node: Node<any>
	local cleanups: { Cleanup } = {}

	local disconnected = false

	local function add_to_cleanups(fn: Cleanup?)
		if type(fn) ~= "function" or disconnected then
			return
		end

		table.insert(cleanups, fn)
	end

	local function do_cleanup()
		local count = #cleanups
		if count <= 0 then
			return
		end

		for index = count, 1, -1 do
			local cleanup = cleanups[index]

			if not cleanup then
				continue
			end

			cleanup()
		end

		table.clear(cleanups)
	end

	local function dispose()
		if not disconnected then
			disconnected = true

			for parent in next, node.parents do
				parent.children[node] = nil
			end

			peek(do_cleanup)
		end
	end

	node = createNode(function()
		if disconnected then
			return
		end

		peek(do_cleanup)
		callback(dispose, add_to_cleanups)
	end)

	evaluate(node)

	return dispose
end

return effect :: ((callback: () -> ()) -> Cleanup) & ((callback: (dispose: () -> ()) -> ()) -> Cleanup) & ((callback: (dispose: () -> (), on_change: (Cleanup) -> ()) -> ()) -> Cleanup)

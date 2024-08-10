local types = require(script.Parent.types)

local depend = require(script.Parent.graph.depend)
local castToNode = require(script.Parent.graph.castToNode)
local evaluate = require(script.Parent.graph.evaluate)
local peek = require(script.Parent.peek)

type Cleanup = () -> ()

type Use = types.Use
type UsedAs<T> = types.UsedAs<T>

type Node = types.Node

local function use(self: Node): Use
	return function<T>(subject: UsedAs<T>): T
		local targetState = castToNode(subject)

		if targetState ~= nil then
			depend(self, targetState)
		end

		return peek(subject)
	end :: Use
end

--[=[
	Runs the given callback immediately and whenever any value it depends on
	changes. Returns a cleanup function that unsubscribes the callback.
	
	@param callback The function to run.
	@return A function that unsubscribes the callback.
]=]
local function effect(callback: (use: Use) -> Cleanup?): Cleanup
	local disconnected = false
	
	local cleanup: Cleanup?
	local gottenCleanupOnce = false

	local node: Node = {
		createdAt = os.clock(),
		parents = {},
		children = table.freeze({}),
		timeliness = "eager",
		state = "dirty",
		version = 0,
		_evaluate = function(self)
			if disconnected then
				return false
			end

			if gottenCleanupOnce and cleanup then
				cleanup()
			end

			local success, result = pcall(callback, use(self))

			if success then
				cleanup = result

				if cleanup and not gottenCleanupOnce then
					gottenCleanupOnce = true
				end
			else
				print(result)
			end
			
			return true
		end,
	}

	evaluate(node, true)

	return function()
		if disconnected then
			return
		end

		disconnected = true

		if cleanup then
			cleanup()
		end

		for parent in node.parents do
			parent.children[node] = nil
		end
	end
end

return effect :: (callback: (use: Use) -> ()) -> Cleanup & (callback: (use: Use) -> Cleanup) -> Cleanup

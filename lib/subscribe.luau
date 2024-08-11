local types = require(script.Parent.types)

local depend = require(script.Parent.graph.depend)
local castToNode = require(script.Parent.graph.castToNode)
local evaluate = require(script.Parent.graph.evaluate)
local peek = require(script.Parent.peek)

type StateObject<T> = types.Value<T> & types.Computed<T>

type Set<T> = types.Set<T>

type Listener<T> = types.Listener<T>
type Cleanup = () -> ()

type Node = types.Node

--[=[
	Subscribes to changes in the given value or computed. The callback is
	called with the current state and the previous state immediately after a
	change occurs.
	
	@param subject The value or computed to subscribe to.
	@param callback The function to call when the state changes.
	@return A function that unsubscribes the callback.
]=]
local function subscribe<T>(subject: StateObject<T>, callback: Listener<T>): Cleanup
	local disconnected = false

	local state = peek(subject)

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

			local targetSubject = castToNode(subject)
			if targetSubject ~= nil then
				depend(self, targetSubject)
			end

			local previousState = state
			state = peek(subject)

			if state ~= previousState then
				local success, message = pcall(function()
					callback(state, previousState)
				end)

				if not success then
					print(message)
				end
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

		for parent in node.parents do
			parent.children[node] = nil
		end
	end
end

return subscribe :: <T>(subject: types.Value<T> | types.Computed<T>, callback: Listener<T>) -> Cleanup

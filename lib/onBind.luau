local types = require(script.Parent.types)

local peek = require(script.Parent.peek)
local subscribe = require(script.Parent.subscribe)

type StateObject<T> = types.Value<T> & types.Computed<T>

type Listener<T> = types.Listener<T>
type Cleanup = () -> ()

--[=[
	Similar to `subscribe()`, but the callback is called immediately
    with the subject's initial values.
	
	@param subject The value or computed to bind to.
	@param callback The function to call when the state changes.
	@return A function that unbinds the callback.
]=]
local function onBind<T>(subject: StateObject<T>, callback: Listener<T>): Cleanup
	local result = peek(subject)
	callback(result, result)

	return subscribe(subject, callback)
end

return onBind :: <T>(subject: types.Value<T> | types.Computed<T>, callback: Listener<T>) -> Cleanup

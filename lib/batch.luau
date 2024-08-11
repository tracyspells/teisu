local types = require(script.Parent.types)

local flags = require(script.Parent.graph.flags)
local updateAll = require(script.Parent.graph.updateAll)

local castToState = require(script.Parent.utils.castToState)

type Value<T> = types.Value<T>
type Array<T> = types.Array<T>

local function add(dependencies: Array<Value<any>>): (...Value<any>) -> ()
	return function(...: Value<any>)
		for index = 1, select("#", ...) do
			local subject: Value<any> = select(index, ...)

			local targetState = castToState(subject)

			if targetState == nil then
				error("you cannot batch non-state objects", 0)
			end

			if targetState.implements.value ~= true then
				error("you cannot batch computed objects", 0)
			end

			table.insert(dependencies, targetState :: Value<any>)
		end
	end
end

--[=[
	Runs the given callback and schedules listeners to be notified
	only once after the callback has completed. Useful for batching 
	multiple changes.

	@param callback The function to run.
]=]
local function batch(callback: (add: (...Value<any>) -> ()) -> ())
	if flags.batch then
		return
	end

	local dependencies: Array<Value<any>> = {}
	flags.batch = true

	local ok, err = pcall(function()
		callback(add(dependencies))
	end)

	flags.batch = false

	if not ok then
		error(`error occured while batching updates: \n{err}`)
	end

	if #dependencies > 0 then
		for _, dependency in next, dependencies do
			local success, result = pcall(function()
				updateAll(dependency)
			end)

			assert(success, result)
		end

		table.clear(dependencies)
	end
end

return batch

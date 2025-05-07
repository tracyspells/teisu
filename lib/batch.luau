local types = require("@types/")
local graph = require("@graph/")
local flags = require("@flags/")

type Set<T> = types.Set<T>
type Map<K, V> = types.Map<K, V>
type Array<T> = types.Array<T>

type Node = types.Node<any>

local evaluate = graph.evaluate
local batched = graph.batched

local function try<T...>(callback: (T...) -> (), on_error: () -> (), on_success: () -> (), ...: T...)
	if flags.strict then
		local thread = coroutine.create(callback, ...)
		local ok, result: string? = coroutine.resume(thread)

		if coroutine.status(thread) == "suspended" then
			local source: string, line: number, name: string = debug.info(callback, "sln")

			coroutine.close(thread)
			on_error()

			error(
				"Cannot yield inside a batch() call. Consider wrapping this code in a Promise, task.spawn, or task.defer instead."
					.. `\nFunction defined at: {source}:{line}`
					.. if name == "" then "" else ` function {name}`
			)
			return
		elseif not ok then
			local source: string, line: number, name: string = debug.info(callback, "sln")
			on_error()

			error(
				"An error occurred while running batching updates"
					.. `\nFunction defined at: {source}:{line}`
					.. (if name == "" then "" else ` function {name}`)
					.. `\nError: {result}`
			)
			return
		end

		on_success()
	else
		local ok, message: string? = pcall(callback, ...)

		if not ok then
			on_error()
			error(message)
			return
		end

		on_success()
	end
end

return function(callback: () -> ())
	if flags.batching then
		return callback()
	end

	local results
	flags.batching = true
	try(callback, function()
		flags.batching = false
		table.clear(batched)
	end, function()
		flags.batching = false

		if next(batched) ~= nil then
			results = table.clone(batched)
			table.clear(batched)
		end
	end)

	if results == nil then
		return
	end

	for eager_node in results do
		evaluate(eager_node)
	end
end

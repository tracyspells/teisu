local types = require("./types")
local flec = require("./flec")
local effect = require("./effect")

type Map<K, V> = types.Map<K, V>
type Molecule<T> = types.Molecule<T>

type MappedConstructor =
	(<K0, V0, K1, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1)) -> Molecule<{ [K1]: V1 }>)
	& (<K0, V0, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> V1?) -> Molecule<{ [K0]: V1 }>)
	& (<K0, V0, K1, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1?)) -> Molecule<{ [K1]: V1 }>)

local function mapped<K0, V0, K1, V1>(molecule: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1?)): Molecule<{ [K1]: V1 }>
	local output = flec({})
	local ref = setmetatable({ current = output }, { __mode = "v" })

	local cache: Map<any, any> = {}
	local remove_queue: { any } = {}

	local dispose
	local cleanup = function()
		table.clear(cache)
		table.clear(remove_queue)
		dispose()
	end

	dispose = effect(function()
		if not ref.current then
			return cleanup()
		end

		local data = molecule()

		-- removed queued values
		for _, key in next, remove_queue do
			if data[key] ~= nil then
				continue
			end
			cache[key] = nil
		end

		table.clear(remove_queue)

		-- process new or changed values
		for key, value in next, data do
			local newValue, newKey = mapper(value, key)
			local v, k = newValue or value, newKey or key

			if cache[k] ~= v then
				cache[k] = v
			end
		end

		output(table.clone(cache))

		return function()
			for key in next, cache do
				table.insert(remove_queue, key)
			end
		end
	end)

	return output
end

return mapped :: MappedConstructor

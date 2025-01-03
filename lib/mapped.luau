local types = require("./types")
local computed = require("./computed")

type Map<K, V> = types.Map<K, V>

type Molecule<T> = types.Molecule<T>

type MappedConstructor =
	(<K0, V0, K1, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1)) -> Molecule<{ [K1]: V1 }>)
	& (<K0, V0, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> V1?) -> Molecule<{ [K0]: V1 }>)
	& (<K0, V0, K1, V1>(subject: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1?)) -> Molecule<{ [K1]: V1 }>)

--[=[
	Maps each entry in a molecule's state to a new key-value pair. If the `mapper`
	function returns `undefined`, the entry is omitted from the resulting map.
	When the molecule changes, the `mapper` is called for each entry in the state
	to compute the new state.
	
	@param subject The molecule to observe.
	@param mapper The function that maps each entry.
	@return A new read-only molecule with the mapped state.
]=]
local function mapped<K0, V0, K1, V1>(molecule: Molecule<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1?)): Molecule<{ [K1]: V1 }>
	local old: Map<any, any>

	return computed(function()
		local items = molecule()

		local new: { [K1]: V1 } = {}

		old = if old == nil then {} else old

		for key, value in next, items do
			local newValue, newKey = mapper(value, key)

			local K1 = (if newKey == nil then key else newKey) :: K1

			local V1 = (if newValue == nil then value else newValue) :: V1
			local oldV1 = old[K1]

			if oldV1 ~= nil and oldV1 == V1 then
				V1 = oldV1
			end

			new[K1] = V1
		end

		old = new

		return new
	end)
end

return mapped :: MappedConstructor

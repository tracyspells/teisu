local types = require(script.Parent.types)

local computed = require(script.Parent.computed)

type StateObject<T> = types.Value<T>| types.Computed<T>
type Computed<T> = types.Computed<T>

type MappedConstructor =
	(<K0, V0, K1, V1>(subject: StateObject<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1)) -> Computed<{ [K1]: V1 }>)
	& (<K0, V0, V1>(subject: StateObject<{ [K0]: V0 }>, mapper: (V0, K0) -> V1?) -> Computed<{ [K0]: V1 }>)
	& (<K0, V0, K1, V1>(subject: StateObject<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1?)) -> Computed<{ [K1]: V1 }>)

--[=[
	Maps each entry in the value's contents to a new key-value pair. If the `mapper`
	function returns `undefined`, the entry is omitted from the resulting map.
	When the atom changes, the `mapper` is called for each entry in the state
	to compute the new state.
	
	@param subject The value or computed to observe.
	@param mapper The function that maps each entry.
	@return A new read-only value with the mapped state.
]=]
local function mapped<K0, V0, K1, V1>(subject: StateObject<{ [K0]: V0 }>, mapper: (V0, K0) -> (V1?, K1?)): Computed<{ [K1]: V1 }>
    return computed(function(use) 
        local mapped: { [K1]: V1 } = {} 
        local items = use(subject)

        for key, item in next, items do
            local newValue, newKey = mapper(item, key)
            
            if newKey == nil then
                newKey = key :: any
            end

            mapped[newKey :: K1] = newValue :: V1
        end

        return mapped
    end)
end

return mapped :: MappedConstructor

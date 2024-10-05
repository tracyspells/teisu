if not game then
	script = require("../test/relative-string")
end

local types = require(script.Parent.types)
local effect = require(script.Parent.effect)

type Map<K, V> = types.Map<K, V>

type Molecule<T> = types.Molecule<T>
type TableMolecule<K, V> = Molecule<Map<K, V>>

type Factory<K, V> = (value: V, key: K) -> Cleanup?
type Cleanup = () -> ()

local function noop() end -- no operations

--[=[
	Creates an instance of `factory` for each item in a molecule's state, and
	cleans up the instance when the item is removed. Returns a cleanup function
	that disconnects from all instances.
	
	@param subject The molecule to observe.
	@param factory The function that tracks the lifecycle of each item.
	@return A function that disconnects from all instances.
]=]
local function observe<K, V>(subject: TableMolecule<K, V>, factory: Factory<K, V>): Cleanup
	local connections: { [K]: Cleanup } = {}

	local dispose = effect(function()
		local state = subject()

		for key, disconnect in connections do
			if state[key] == nil then
				connections[key] = nil
				disconnect()
			end
		end

		for key, value in state do
			if not connections[key] then
				connections[key] = factory(value, key) or noop
			end
		end
	end)

	return function()
		for _, disconnect in next, connections do
			disconnect()
		end

		table.clear(connections)
		dispose()
	end
end

return observe :: <K, V>(
	subject: TableMolecule<K, V>,
	factory: (value: V, key: K) -> ()
) -> Cleanup & <K, V>(subject: TableMolecule<K, V>, factory: (value: V, key: K) -> Cleanup) -> Cleanup

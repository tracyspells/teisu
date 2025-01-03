local types = require("./types")
local subscribe = require("./subscribe")
local peek = require("./peek")

type Map<K, V> = types.Map<K, V>

type Molecule<T> = types.Molecule<T>
type TableMolecule<K, V> = Molecule<Map<K, V>>

type UsedAs<T> = types.UsedAs<T>

type Factory<K, V> = (value: V, key: K) -> (() -> ())?
type Cleanup = () -> ()

local function noop() end

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

	local unsubscribe = subscribe(subject, function(new, old)
		for key, disconnect in connections do
			if new[key] == nil and old[key] ~= nil then
				connections[key] = nil
				disconnect()
			end
		end

		for key, value in next, new do
			if not connections[key] then
				connections[key] = factory(value, key) or noop
			end
		end
	end)

	local result = peek(subject)

	if result ~= nil then
		for key, value in next, result do
			if not connections[key] then
				connections[key] = factory(value, key) or noop
			end
		end
	end

	return function()
		for _, disconnect in next, connections do
			disconnect()
		end

		table.clear(connections)
		unsubscribe()
	end
end

return observe :: <K, V>(
	subject: TableMolecule<K, V>,
	factory: (value: V, key: K) -> ()
) -> Cleanup & <K, V>(subject: TableMolecule<K, V>, factory: (value: V, key: K) -> Cleanup) -> Cleanup

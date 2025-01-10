local types = require("@types/")
local subscribe = require("@subscribe/")
local peek = require("@peek/")

type Map<K, V> = types.Map<K, V>
type Cleanup = types.Cleanup

type Molecule<T> = types.Molecule<T>
type MapMolecule<K, V> = Molecule<Map<K, V>>
type UsedAs<T> = types.UsedAs<T>

type Factory<K, V> = (value: V, key: K) -> Cleanup?

local function noop() end

local function observe<K, V>(subject: MapMolecule<K, V>, factory: Factory<K, V>): Cleanup
	local connections: { [K]: Cleanup } = {}
	local unsubscribe = subscribe(subject, function(new, old)
		for key, value in next, old do
			if new[key] == nil then
				local disconnect = connections[key]
				connections[key] = nil
				disconnect()
			end
		end

		for key, value in next, new do
			if old[key] == nil then
				connections[key] = factory(value, key) or noop
			end
		end
	end)

	local result = peek(subject)

	if type(result) == "table" then
		for key, value in next, result do
			if not connections[key] then
				connections[key] = peek(function()
					return factory(value, key) or noop
				end)
			end
		end
	end

	return function()
		for _, disconnect in next, connections do
			peek(disconnect)
		end

		table.clear(connections)
		unsubscribe()
	end
end

return observe :: <K, V>(
	subject: MapMolecule<K, V>,
	factory: (value: V, key: K) -> ()
) -> Cleanup & <K, V>(subject: MapMolecule<K, V>, factory: (value: V, key: K) -> Cleanup) -> Cleanup

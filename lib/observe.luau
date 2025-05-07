local types = require("@types/")
local graph = require("@graph/")
local subscribe = require("@subscribe/")
local peek = require("@peek/")

type Map<K, V> = types.Map<K, V>
type Cleanup = types.Cleanup
type Molecule<T> = types.Molecule<T>
type MapMolecule<K, V> = Molecule<Map<K, V>>
type UsedAs<T> = types.UsedAs<T>
type Factory<K, V> = (value: V, key: K) -> Cleanup?

local get_scope = graph.get_scope

local function noop() end

local function observe<K, V>(subject: MapMolecule<K, V>, factory: Factory<K, V>): Cleanup
	local connections: { [K]: Cleanup } = {}
	local unsubscribe

	local function listener(new: Map<K, V>)
		if type(new) ~= "table" then
			return
		end

		local scope = get_scope()
		local previous_cleanups

		-- we'll need to disable cleanups here 
		-- so that we can handle our own cleanups
		if scope then
			previous_cleanups = scope.cleanups
			scope.cleanups = false
		end

		for key, disconnect in connections do
			if new[key] == nil then
				connections[key] = nil
				disconnect()
			end
		end

		for key, value in new do
			if connections[key] == nil then
				connections[key] = factory(value, key) or noop
			end
		end

		if scope then
			scope.cleanups = previous_cleanups :: any
		end
	end
	
	local function disconnect()
		for _, disconnect in connections do
			peek(disconnect)
		end

		table.clear(connections)
		unsubscribe()
	end

	unsubscribe = subscribe(subject, listener)

	peek(function()
		listener(subject())

		return nil
	end)

	return disconnect
end

return observe :: (<K, V>(subject: MapMolecule<K, V>, factory: (value: V, key: K) -> ()) -> Cleanup) 
& ( <K, V>(subject: MapMolecule<K, V>, factory: (value: V, key: K) -> Cleanup) -> Cleanup)

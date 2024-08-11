-- Credits go to Littensy: https://github.com/littensy/charm/blob/main/src/sync/client.luau

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local types = require(script.Parent.Parent.types)

local subscribe = require(script.Parent.Parent.subscribe)
local peek = require(script.Parent.Parent.peek)

local isStrictTable = require(script.Parent.Parent.utils.isStrictTable)

local setInterval = require(script.Parent.setInterval)
local deltaTable = require(script.Parent.deltaTable)

type NetworkPayload = types.NetworkPayload

type MockServerSyncer = types.MockServerSyncer
type ServerSyncer  = types.ServerSyncer 
type ServerOptions = types.ServerOptions

type StatesMap = Dictionary<string, types.Value<any>>

type Dictionary<K, V> = types.Dictionary<K, V>
type Set<T> = { [T]: boolean }


local IS_SERVER = RunService:IsServer()
local IS_TESTING = RunService:IsStudio() and RunService:IsRunning()

local ERROR_MESSAGES = {
	ServerOnly = "'sync.server()' must be called from the server!",
	Start = "'sync:connect()' must be called before 'server:%s()'!",
	Options = "The 'options' argument in 'sync.server()' must be a table, got %s",
	Values = [[
        The 'value' key in 'options' configuration must be a map of values!
        (i.e. { [string]: Value<any> })
    ]],
}

local function server(options: ServerOptions): ServerSyncer
	if not IS_TESTING and not IS_SERVER then
		error(ERROR_MESSAGES.ServerOnly)
	end

	if not isStrictTable(options) then
		error(string.format(ERROR_MESSAGES.Options, typeof(options)))
	end

	if not isStrictTable(options.values) then
		error(ERROR_MESSAGES.Values)
	end

	local playersConnected: Set<Player> = {}

	local snapshots: { Dictionary<string, any> } = {}
	local changed = false

	local connections: { () -> () } = {}
	local sync: (player: Player, ...NetworkPayload) -> ()

	local function getSnapshot()
		local snapshot: Dictionary<string, any> = {}

		for key, value in next, options.values do
			snapshot[key] = peek(value)
		end

		return snapshot
	end

	local function pushSnapshot(key: string, current: any, previous: any)
		if not options.preserveHistory then
			if snapshots[2] then
				snapshots[2][key] = current
			else
				snapshots[2] = getSnapshot()
			end
			
			return
		end

		local lastSnapshot = snapshots[#snapshots]
		local previousSnapshot = snapshots[#snapshots - 1]

		if previousSnapshot and previousSnapshot[key] == previous and lastSnapshot[key] == previous then
			lastSnapshot[key] = current
		else
			local nextSnapshot = table.clone(lastSnapshot)
			nextSnapshot[key] = current

			table.insert(snapshots, nextSnapshot)
		end
	end

	Players.PlayerRemoving:Connect(function(player)
		if playersConnected[player] then
			playersConnected[player] = nil
		end
	end)

	local self = {} :: ServerSyncer

	function self:connect(callback)
		sync = callback

		-- step 1: get our states and setup connections for state changes
		table.insert(snapshots, getSnapshot())
		for key, value in options.values do
			table.insert(
				connections,
				subscribe(value, function(new, old)
					pushSnapshot(key, new, old)
					changed = true
				end)
			)
		end

		-- step 2: send players delta snapshots of shared state
		table.insert(
			connections,
			setInterval(function()
				if not changed then
					return
				end

				local payloads: { NetworkPayload } = {}
				local lastSnapshot

				for index, snapshot in next, snapshots do
					lastSnapshot = snapshot

					if index == 1 then
						continue
					end

					table.insert(payloads, {
						type = "diff",
						contents = deltaTable.delta(snapshots[index - 1], snapshot),
					})
				end

				snapshots = { lastSnapshot }
				changed = false

				for player in playersConnected do
					task.spawn(callback, player, unpack(payloads))
				end
			end, options.interval)
		)

		return function()
			for _, disconnect in connections do
				disconnect()
			end

			table.clear(connections)
		end
	end

	function self:hydrate(player)
		if not sync then
			error(string.format(ERROR_MESSAGES.Start, "hydrate"))
		end

		local isConnected = playersConnected[player]

		if isConnected then
			return
		end

		playersConnected[player] = true

		sync(player, { type = "full", contents = snapshots[#snapshots] })
	end

	(self :: MockServerSyncer)._sendDiff = function(_, player)
		if not sync then
			error(string.format(ERROR_MESSAGES.Start, "sendDiff"))
		end

		local isConnected = playersConnected[player]

		if not isConnected then
			return
		end

		if not changed then
			return
		end

		local payloads: { NetworkPayload } = {}
		local lastSnapshot

		for index, snapshot in next, snapshots do
			lastSnapshot = snapshot

			if index == 1 then
				continue
			end

			table.insert(payloads, {
				type = "diff",
				contents = deltaTable.delta(snapshots[index - 1], snapshot),
			})
		end

		snapshots = { lastSnapshot }
		changed = false

		sync(player, unpack(payloads))
	end

	return self
end

return server

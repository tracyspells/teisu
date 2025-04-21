local types = require("@types/")
local patch = require("@patch/")
local subscribe = require("@subscribe/")

type Set<T> = types.Set<T>
type Array<T> = types.Array<T>
type Cleanup = types.Cleanup
type SyncPayload = types.SyncPayload

type Flec<T> = types.Flec<T>

export type Options = {
	flecs: { [string | number]: Flec<any> },
	interval: number?,
}

type ServerInstance<K = string | number, V = any> = {
	changes: number,
	flecs: { [K]: Flec<V> },
	interval: number,
	players_connected: Set<Player>,
	players_to_hydrate: Set<Player>,
	previous_snapshot: { [K]: V }?,
	current_snapshot: { [K]: V }?,
	sync: ((Player, SyncPayload) -> ())?,
}

type Server = {
	hydrate: (self: Server, player: Player) -> (),
	connect: (self: Server, callback: (Player, SyncPayload) -> ()) -> Cleanup,
}

local server_instance: ServerInstance<any, any>?
local diff = patch.diff

local function createSnapshot(flecs: { [string | number]: Flec<any> })
	local snapshot = {}

	for key, flec in next, flecs do
		snapshot[key] = flec()
	end

	return snapshot
end

local function server(options: Options): Server
	if game and server_instance then
		warn(`server has already initialized`)
		return nil :: never
	end

	local flecs, interval = options.flecs, options.interval or 0

	local instance = {
		changes = 0,
		interval = interval,
		flecs = flecs,
		players_connected = {},
		players_to_hydrate = {},
		sync = nil,
	}
	server_instance = instance

	local self = {} :: Server

	function self:hydrate(player: Player)
		assert(instance.sync, `self:connect() must be called before self:hydrate()!`)
		assert(not instance.players_connected[player], `player {player} has already been connected`)

		instance.players_connected[player] = true
		instance.players_to_hydrate[player] = true
	end

	function self:connect(callback: (Player, SyncPayload) -> ())
		local connections = {}

		instance.previous_snapshot = createSnapshot(flecs)
		instance.current_snapshot = table.clone(instance.previous_snapshot)

		for key, flec in flecs do
			table.insert(connections, subscribe(flec, function(new)
				instance.current_snapshot[key] = new  
				instance.changes += 1
			end))
		end

		instance.sync = callback :: any

		return function()
			for i = #connections, 1, -1 do
				local disconnect = connections[i]
				disconnect()
			end

			table.clear(connections)

			if not game then
				table.clear(instance.players_connected)
			end
		end
	end

	if game then
		game:GetService("Players").PlayerRemoving:Connect(function(player)
			instance.players_connected[player] = nil
			instance.players_to_hydrate[player] = nil
		end)
	end

	return self
end

local function step()
	local accumulator = 0

	return function(dt: number)
		if not server_instance or not server_instance.sync then
			return
		end

		-- send full state to players that just joined
		if server_instance.current_snapshot then
			for player in server_instance.players_connected do
				if not server_instance.players_to_hydrate[player] then
					continue
				end

				server_instance.sync(player, { type = "init", data = server_instance.current_snapshot })
				server_instance.players_to_hydrate[player] = nil
			end
		end

		if server_instance.interval < 0 then
			return
		end

		accumulator += dt

		if accumulator < server_instance.interval then
			return
		end
		accumulator = 0

		if
			server_instance.changes <= 0
			or not server_instance.current_snapshot
			or not server_instance.previous_snapshot
		then
			return
		end

		local delta = diff(server_instance.previous_snapshot, server_instance.current_snapshot)
	
		for player in server_instance.players_connected do
			if server_instance.players_to_hydrate[player] then
				continue
			end

			server_instance.sync(player, { type = "patch", data = delta :: any })
		end

		server_instance.changes = 0
		server_instance.previous_snapshot = table.clone(server_instance.current_snapshot)
	end
end

return table.freeze {
	server = server,
	step = step,
}

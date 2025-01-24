local types = require("@types/")
local patch = require("@patch/")
local effect = require("@effect/")

type Set<T> = types.Set<T>
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
		previous_snapshot = nil,
		current_snapshot = nil,
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
		local dispose = effect(function()
			instance.current_snapshot = createSnapshot(flecs) :: any

			if instance.previous_snapshot and instance.current_snapshot then
				for key, prev_value in instance.previous_snapshot do
					local curr_value = instance.current_snapshot[key]

					if prev_value ~= curr_value then
						instance.changes += 1
					end
				end
			end

			return function()
				if instance.current_snapshot then
					instance.previous_snapshot = table.clone(instance.current_snapshot) :: any
				end
			end
		end)

		instance.sync = callback :: any

		return function()
			dispose()

			if not game then
				table.clear(instance.players_connected)
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
		server_instance.changes = 0

		for player in server_instance.players_connected do
			if server_instance.players_to_hydrate[player] then
				continue
			end
			server_instance.sync(player, { type = "patch", data = delta :: any })
		end
	end
end

return table.freeze {
	server = server,
	step = step,
}

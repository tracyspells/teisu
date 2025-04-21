local types = require("@types/")
local animation = require("@animation/")
local creation = require("@creation/")
local sync = require("@sync/")
local action = require("@action/")
local conditions = require("@conditions/")
local flec = require("@flec/")
local subscribe = require("@subscribe/")
local effect = require("@effect/")
local observe = require("@observe/")
local computed = require("@computed/")
local peek = require("@peek/")
local mapped = require("@mapped/")
local batch = require("@batch/")

export type Flec<T> = types.Flec<T>
export type flec<T> = Flec<T>
export type Molecule<T> = types.Molecule<T>
export type molecule<T> = Molecule<T>
export type Derivable<T> = types.UsedAs<T>
export type derivable<T> = Derivable<T>
export type Spring<T> = types.Spring<T>
export type spring<T> = Spring<T>
export type SyncPayload = types.SyncPayload
export type sync_payload = SyncPayload

local update_springs = animation.step_springs()
local update_server = sync.step_server()

local mount, new, root, _apply = creation.mount, creation.new, creation.root, creation.apply
local cleanup = creation.cleanup

local stepped: RBXScriptConnection?
local is_game = game ~= nil
local is_server = is_game and game:GetService("RunService"):IsServer()

local function on_step(deltaTime: number)
	if is_game then
		debug.profilebegin("TEISU STEP")
		debug.profilebegin("TEISU SPRING")
	end

	update_springs(deltaTime)

	if is_game then
		debug.profileend()
		debug.profileend()
	end

	if not is_game or is_server then
		if is_game then
			debug.profilebegin("TEISU SYNC")
		end

		update_server(deltaTime)

		if is_game then
			debug.profileend()
		end
	end
end

local function apply(instance: Instance)
	return function(props: { [any]: any })
		local unroot = root(function()
			_apply(instance, props)
		end)
		instance.Destroying:Once(unroot)
		return instance
	end
end

stepped = is_game and game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
	on_step(deltaTime)
end)

return table.freeze {

	-- ui
	new = new,

	-- mounting
	root = root,
	mount = mount,
	apply = apply,

	-- core
	flec = flec,
	computed = computed,
	effect = effect,
	show = conditions.show,
	switch = conditions.switch,

	-- utils
	batch = batch,
	mapped = mapped,
	observe = observe,
	subscribe = subscribe,
	cleanup = cleanup,
	peek = peek,

	-- actions
	action = action.action,
	changed = action.changed,

	-- animations
	spring = animation.spring,

	-- networking
	client = sync.client,
	server = sync.server,
	is_none = sync.is_none,

	-- runtime
	step = function(deltaTime: number)
		if stepped and stepped.Connected then
			stepped:Disconnect()
			stepped = nil
		end

		on_step(deltaTime)
	end,
}

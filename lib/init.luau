local types = require("@types/")
local animation = require("@animation/")
local creation = require("@creation/")
local sync = require("@sync/")
local action = require("@action/")
local conditions = require("@conditions/")
local flags = require("@flags/")
local mapped = require("@mapped/")
local flec = require("@flec/")
local subscribe = require("@subscribe/")
local effect = require("@effect/")
local observe = require("@observe/")
local computed = require("@computed/")
local peek = require("@peek/")
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
export type syncPayload = SyncPayload
export type Animatable = types.Animatable
export type animatable = Animatable
export type EasingStyle = types.EasingStyle
export type easingStyle = EasingStyle
export type EasingDirection = types.EasingDirection
export type easingDirection = EasingDirection

local update_animations = animation.step()
local update_server = sync.step_server()

local mount, new, root = creation.mount, creation.new, creation.root
local cleanup = creation.cleanup

local stepped: RBXScriptConnection?
local is_game = game ~= nil
local is_server = is_game and game:GetService("RunService"):IsServer()

local function on_step(deltaTime: number)
	if is_game then
		debug.profilebegin("TEISU ANIMATION")
	end

	update_animations(deltaTime)

	if is_game then
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
		creation.apply(instance, props)
		
		return instance
	end
end

local function strict(value: boolean?): boolean
	if type(value) == "boolean" then
		flags.strict = value
	end

	return flags.strict
end

stepped = is_game and game:GetService("RunService").Heartbeat:Connect(function(deltaTime)
	task.defer(on_step, deltaTime)
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

	-- conditions
	show = conditions.show,
	switch = conditions.switch,

	-- utils
	batch = batch,
	observe = observe,
	subscribe = subscribe,
	cleanup = cleanup,
	peek = peek,

	-- tables
	keys = mapped.keys,
	values = mapped.values,
	indexes = mapped.indexes,

	-- actions
	action = action.action,
	changed = action.changed,

	-- animations
	spring = animation.spring,
	tween = animation.tween,

	-- networking
	client = sync.client,
	server = sync.server,
	is_none = sync.is_none,

	-- flags
	strict = strict,

	-- runtime
	step = function(deltaTime: number)
		if stepped and stepped.Connected then
			stepped:Disconnect()
			stepped = nil
		end

		on_step(deltaTime)
	end,
}

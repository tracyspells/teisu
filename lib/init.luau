local types = require("@types/")
local animation = require("@animation/")
local creation = require("@creation/")
local action = require("@action/")
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

local update_springs = animation.step_springs()

local mount, new, root, _apply = creation.mount, creation.new, creation.root, creation.apply
local cleanup = creation.cleanup

local stepped: RBXScriptConnection?
local is_game = game ~= nil

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

	-- state management
	flec = flec,
	computed = computed,
	effect = effect,
	mapped = mapped,
	observe = observe,
	subscribe = subscribe,
	peek = peek,
	batch = batch,

	-- utils
	cleanup = cleanup,

	-- actions
	action = action.action,
	changed = action.changed,
	input_began = action.input_began,
	input_changed = action.input_changed,
	input_ended = action.input_ended,

	-- animations
	spring = animation.spring,

	-- runtime
	step = function(deltaTime: number)
		if stepped and stepped.Connected then
			stepped:Disconnect()
			stepped = nil
		end

		on_step(deltaTime)
	end,
}

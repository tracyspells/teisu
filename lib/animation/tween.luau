local typeof = game and typeof or require("@mock/").typeof
local task = game and task or require("@mock/").task

local types = require("@types/")
local graph = require("@graph/")
local convert = require("@convert/")
local easing_styles = require("@easing_styles/")
local peek = require("@peek/")
local effect = require("@effect/")

type Molecule<T> = types.Molecule<T>
type UsedAs<T> = types.UsedAs<T>
type Node<T> = types.Node<T>
type Cleanup = types.Cleanup

type EasingDirection = types.EasingDirection
type EasingStyle = types.EasingStyle

type Tween<T> = types.Tween<T>
type TweenState<T> = {
	goal: T,
	goalType: string,

	completed: boolean?,

	direction: EasingDirection,
	style: EasingStyle,
	get_alpha: (number) -> number,

	time_elapsed: number,
	progress: number,
	duration: number,
	delay: number,

	reverses: boolean,
	reversing: boolean?,

	repeats: number,
	repeat_count: number,

	value_count: number,
	start_pos: { number },
	pos: { number },
	target_pos: { number },

	onCompleteListeners: { [number]: (...any) -> (), n: number },
}

type TweenProps = {
	direction: UsedAs<EasingDirection>?,
	style: UsedAs<EasingStyle>?,
	duration: UsedAs<number>?,
	delay: UsedAs<number>?,
	reverses: UsedAs<boolean>?,
	repeats: UsedAs<number>?,
}

local createSourceNode = graph.createSourceNode
local get_scope = graph.get_scope
local push_child_to_scope = graph.push_child_to_scope
local push_cleanup = graph.push_cleanup

-- maps tween data to its corresponding output node
-- lifetime of tween data is tied to output node
local tweens: { [TweenState<unknown>]: Node<unknown> } = setmetatable({} :: any, { __mode = "v" })

local INFINITY = math.huge

local DEFAULT_TWEEN_PROPS = {
	direction = "In" :: EasingDirection,
	style = "Linear" :: EasingStyle,
	duration = 1,
	delay = 0,
	reverses = false,
	repeats = 0,
}

local function get_tween_props(props: TweenProps?): TweenProps
	if not props then
		return DEFAULT_TWEEN_PROPS
	end

	for key, value in DEFAULT_TWEEN_PROPS do
		if props[key] == nil then
			props[key] = value
		end
	end

	return props
end

local function is_NaN(value: number)
	if value ~= value then
		return true
	end

	if value == -INFINITY or value == INFINITY then
		return true
	end

	return false
end

local function is_valid_direction(value: any): boolean
	if type(value) ~= "string" then
		return false
	end

	if value == "In" or value == "Out" or value == "InOut" then
		return true
	end

	return false
end

local function step_tweens(dt: number)
	for tween in tweens do
		if tween.repeats ~= 0 and tween.repeat_count > tween.repeats and not tween.completed then
			tween.completed = true
		end

		if tween.completed then
			continue
		end

		tween.time_elapsed += dt

		if tween.delay > 0 and tween.time_elapsed < tween.delay then
			continue
		end

		tween.progress = math.min(tween.progress + dt, tween.duration)

		local start, goal, current  = tween.start_pos, tween.target_pos, tween.pos

		local blend
	
		if tween.reversing then
			blend = 1 - tween.progress / tween.duration
		else 
			blend = tween.progress / tween.duration
		end

		blend = math.clamp(tween.get_alpha(blend), 0, 1)

		for i = 1, tween.value_count do
			local p, g = start[i], goal[i]
			local result = p + (g - p) * blend
			current[i] = result
		end

		if tween.progress == tween.duration then
			if tween.reversing then
				tween.reversing = nil
				tween.progress = 0
				tween.repeat_count += 1
			else
				if tween.reverses then
					tween.progress = 0
					tween.reversing = true
				else
					tween.progress = 0
					tween.repeat_count += 1
				end
			end
		end
	end
end

local function update_tween_sources()
	local results: { Node<unknown> } = {}
	
	for tween, output in tweens do
		local result = convert[tween.goalType].pack(tween.pos)

		output.cache = result
		table.insert(results, output)

		if tween.completed then
			if tween.onCompleteListeners.n > 0 then
				for _, listener in ipairs(tween.onCompleteListeners) do
					task.spawn(listener, result)
				end
			end

			tween.repeat_count = 1
			tween.time_elapsed = 0
			tween.progress = 0
			tween.completed = nil
			tween.reversing = nil
			tweens[tween] = nil
		end
	end

	return results
end

local function step()
	return step_tweens, update_tween_sources
end

local function is_tween(value: any): boolean
	local meta = getmetatable(value)
	return if meta ~= nil and meta.type == "Tween" then true else false
end

local function tween<T>(source: Molecule<T>, props: TweenProps?): Tween<T>
	local tween_props = get_tween_props(props)

	local owner = get_scope()

	local output = createSourceNode(nil :: T?)
	output.nickname = "tween"

	local state = {} :: TweenState<T>
	state.repeat_count = 1
	state.value_count = 0
	state.time_elapsed = 0
	state.progress = 0
	state.onCompleteListeners = { n = 0 } :: { [number]: (value: T) -> (), n: number }

	local self = {}

	function self.onComplete(callback: (value: T) -> ()): Cleanup
		if output == nil then
			error(`tween has been destroyed`)
		end

		local id = state.onCompleteListeners.n + 1
		state.onCompleteListeners.n = id
		state.onCompleteListeners[id] = callback

		return function()
			if state.onCompleteListeners == nil or state.onCompleteListeners.n == nil then
				return
			end

			state.onCompleteListeners.n = id - 1
			state.onCompleteListeners[id] = nil
		end
	end

	local cleaned_up = false
	local updates = -1
	local dispose
	local cleanup = function()
		if cleaned_up then
			return
		end

		cleaned_up = true
		updates = nil :: never

		if tweens[state] then
			tweens[state] = nil
		end

		state = nil :: never

		if dispose and not owner then
			dispose()
			dispose = nil :: never
		end

		output = nil :: never
	end

	setmetatable(
		self,
		table.freeze({
			type = "Tween",
			__call = function(_, ...: any)
				if cleaned_up then
					return nil :: any
				end

				if select("#", ...) == 0 then
					local scope = get_scope()
			
					if scope then
						if scope.type == "cleanup" and not owner then
							return push_cleanup(scope, cleanup, self)
						end

						push_child_to_scope(scope, output)
					end

					return output.cache :: T
				end

				local target = ...

				if target ~= graph.NODE_KEY then
					return nil :: never
				end

				return output
			end,
		})
	)

	self = table.freeze(self)

	if owner then
		push_cleanup(owner, cleanup, self)
	end

	dispose = effect(function()
		local changes = 0

		local duration = peek(tween_props.duration, true) :: number
		local style = peek(tween_props.style, true)
		local direction: EasingDirection = peek(tween_props.direction, true)
		local delay = peek(tween_props.delay, true)
		local reverses = peek(tween_props.reverses, true)
		
		local repeats = peek(tween_props.repeats, true)
		repeats = math.max(repeats, -1) + 1
		
		local goal = source()
		local goal_type = typeof(goal)

		updates += 1

		if state.delay ~= delay then
			state.delay = math.max(delay, 0)
			changes += 1
		end

		if state.duration ~= duration then
			state.duration = duration
			changes += 1
		end

		if state.reverses ~= reverses then
			state.reverses = reverses
			changes += 1
		end

		if state.repeats ~= repeats then
			state.repeats = repeats
			changes += 1
		end

		local did_style_or_direction_change = false
		if state.style ~= style and easing_styles[style] then
			state.style = style
			changes += 1
			did_style_or_direction_change = true
		end

		if state.direction ~= direction and is_valid_direction(direction) then
			state.direction = direction
			changes += 1
			did_style_or_direction_change = true
		end

		if did_style_or_direction_change then
			state.get_alpha = function(value: number)
				return easing_styles[state.style][state.direction](value)
			end
		end

		if state.goal ~= goal then
			local is_number = goal_type == "number"

			if not is_number then
				state.goal = goal
				changes += 1
			else
				if not is_NaN(goal :: any) then
					state.goal = goal
					changes += 1
				else
					error(`[tween]: cannot animate a goal that is NaN, -infinity, or infinity`)
				end
			end
		end

		if state.goalType ~= goal_type then
			if updates > 0 then
				error(`[tween]: can only animate one type. got {goal_type} when it should be {state.goalType}`)
			end

			state.goalType = goal_type
			changes += 1
		end

		if changes > 0 then
			local last_target_pos = state.target_pos
			
			if last_target_pos then
				last_target_pos = table.clone(last_target_pos)
			end

			local data = convert[goal_type].unpack(goal) :: { number }
			state.value_count = #data
			state.target_pos = data

			if updates == 0 then
				output.cache = state.goal
				
				state.pos = table.create(state.value_count, 0)
			end

			if updates > 0 then
				state.start_pos = last_target_pos
				tweens[state] = output
			end
		end
	end)

	return self :: any
end

return table.freeze({
	tween = tween,
	is_tween = is_tween,
	step = step,
})

local typeof = game and typeof or require("@mock/").typeof
local task = game and task or require("@mock/").task

local types = require("@types/")
local graph = require("@graph/")
local convert = require("@convert/")
local peek = require("@peek/")
local effect = require("@effect/")

type Molecule<T> = types.Molecule<T>
type UsedAs<T> = types.UsedAs<T>
type Spring<T> = types.Spring<T>
type Node<T> = types.Node<T>
type Cleanup = types.Cleanup
type SpringState<T> = {
	goal: T,
	goalType: string,
	speed: number,
	damping: number,
	k: number, -- spring constant
	c: number, -- damping coefficient
	
	completed: boolean?,

	value_count: number,
	pos: { number },
	target_pos: { number },
	vel: { number },

	onCompleteListeners: { [number]: (...any) -> (), n: number },
}

local createSourceNode = graph.createSourceNode
local get_scope = graph.get_scope
local push_child_to_scope = graph.push_child_to_scope
local push_cleanup = graph.push_cleanup

-- maps spring data to its corresponding output node
-- lifetime of spring data is tied to output node
local springs: { [SpringState<unknown>]: Node<unknown> } = setmetatable({} :: any, { __mode = "v" })

local VELOCITY_EPSILON = 1E-3
local POSITION_EPSILON = 1E-4

local PI = math.pi
local TAU = 2 * PI

local INFINITY = math.huge

local function is_NaN(value: number)
	if value ~= value then
		return true
	end

	if value == -INFINITY or value == INFINITY then
		return true
	end

	return false
end

local function step_springs(dt: number)
	for spring in springs do
		if spring.completed then continue end
		
		local pos, vel, goal = spring.pos, spring.vel, spring.target_pos
		local completed = 0

		for i = 1, spring.value_count do
			local p, v, g = pos[i], vel[i], goal[i]

			-- calculate displacement
			local delta = p - g

			local spring_force = delta * -spring.k
			local friction_force = v * -spring.c

			local accel = (spring_force + friction_force) * dt

			v += accel
			p += v * dt

			if math.abs(v) < VELOCITY_EPSILON and math.abs(p - g) < POSITION_EPSILON then
				completed += 1
				pos[i], vel[i] = g, 0
			else
				pos[i], vel[i] = p, v
			end
		end

		if completed == spring.value_count then
			spring.completed = true
		end
	end
end

local function update_spring_sources()
	local results: { Node<unknown> } = {}
	
	for spring, output in springs do
		local result = convert[spring.goalType].pack(spring.pos)
		
		output.cache = result
		table.insert(results, output)

		if spring.completed then
			if spring.onCompleteListeners.n > 0 then
				for _, listener in ipairs(spring.onCompleteListeners) do
					task.spawn(listener, result)
				end
			end

			spring.completed = nil
			springs[spring] = nil
		end
	end

	return results
end

local function step()
	return step_springs, update_spring_sources
end

local function is_spring(value: any): boolean
	local meta = getmetatable(value)
	return if meta ~= nil and meta.type == "Spring" then true else false
end

local function spring<T>(source: Molecule<T>, speed: UsedAs<number>?, damping: UsedAs<number>?): Spring<T>
	local owner = get_scope()

	local output = createSourceNode(nil :: T?)
	output.nickname = "spring"

	local state = {} :: SpringState<T>
	state.onCompleteListeners = { n = 0 } :: { [number]: (value: T) -> (), n: number }

	local self = {}

	function self.impulse(_, delta: T)
		if output == nil then
			error(`spring has been destroyed`)
		end

		local delta_type = typeof(delta)

		if delta_type ~= state.goalType then
			error(`spring types don't match; got {delta_type} when it should be {state.goalType}`)
		end

		local newStartVel = convert[delta_type].unpack(delta)

		for index, vel in state.vel do
			newStartVel[index] += vel
		end

		state.completed = false
		state.vel = newStartVel

		springs[state] = output
	end

	function self.setPosition(_, newValue: T)
		if output == nil then
			error(`spring has been destroyed`)
		end

		local new_type = typeof(newValue)

		if new_type ~= state.goalType then
			error(`spring types don't match; got {new_type} when it should be {state.goalType}`)
		end

		state.completed = false
		state.pos = convert[new_type].unpack(newValue)

		springs[state] = output
	end

	function self.setVelocity(_, newValue: T)
		if output == nil then
			error(`spring has been destroyed`)
		end

		local new_type = typeof(newValue)

		if new_type ~= state.goalType then
			error(`spring types don't match; got {new_type} when it should be {state.goalType}`)
		end

		state.completed = false
		state.vel = convert[new_type].unpack(newValue)

		springs[state] = output
	end

	function self.onComplete(callback: (value: T) -> ()): Cleanup
		if output == nil then
			error(`spring has been destroyed`)
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

		if springs[state] then
			springs[state] = nil
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
		table.freeze {
			type = "Spring",
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

					return output.cache  :: T
				end

				local target = ...

				if target ~= graph.NODE_KEY then
					return nil :: never
				end

				return output
			end,
		}
	)

	self = table.freeze(self)

	if owner then
		push_cleanup(owner, cleanup, self)
	end

	dispose = effect(function()
		local goal, _speed, _damping = source(), peek(speed or 1, true), peek(damping or 1, true)
		local changes = 0

		local goal_type = typeof(goal)

		updates += 1

		if state.damping ~= _damping then
			if typeof(_damping) ~= "number" then
				error(`[spring]: damping property must be a number`)
			end

			if not is_NaN(_damping) then
				state.damping = _damping
				changes += 1
			else
				error(`[spring]: cannot set damping property to NaN, -infinity, or infinity`)
			end
		end

		if state.speed ~= _speed then
			if typeof(_damping) ~= "number" then
				error(`[spring]: speed property must be a number`)
			end

			if not is_NaN(_speed) then
				state.speed = _speed
				changes += 1
			else
				error(`[spring]: cannot set speed property to NaN, -infinity, or infinity`)
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
					error(`[spring]: cannot animate a goal that is NaN, -infinity, or infinity`)
				end
			end
		end

		if state.goalType ~= goal_type then
			state.goalType = goal_type
			changes += 1
		end

		if changes > 0 then
			local old_value_count = state.value_count
			local data = convert[goal_type].unpack(goal) :: { number }
			state.value_count = #data
			state.target_pos = data

			local n = (TAU / state.speed)
			local k = n * n
			local c = (4 * PI * state.damping) / state.speed
			state.k, state.c = k, c

			if updates == 0 then
				output.cache = state.goal
				state.pos, state.vel = table.clone(state.target_pos), table.clone(state.target_pos)
			elseif updates > 0 and old_value_count ~= state.value_count then
				if old_value_count > state.value_count then
					local removals = old_value_count - state.value_count
					for _ = 1, removals do
						table.remove(state.pos)
						table.remove(state.vel)
					end
				elseif state.value_count > old_value_count then
					for i = old_value_count + 1, state.value_count do
						table.insert(state.pos, 0)
						table.insert(state.vel, 0)
					end
				end
			end

			if updates > 0 then
				springs[state] = output
			end
		end
	end)

	return self :: any
end

return table.freeze {
	spring = spring,
	is_spring = is_spring,
	step = step,
}

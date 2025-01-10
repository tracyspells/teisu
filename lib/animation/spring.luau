local typeof = game and typeof or require("@mock/").typeof

local types = require("@types/")
local graph = require("@graph/")
local convert = require("@convert/")
local peek = require("@peek/")
local effect = require("@effect/")

type Molecule<T> = types.Molecule<T>
type UsedAs<T> = types.UsedAs<T>
type Spring<T> = types.Spring<T>
type Node<T> = types.Node<T>

type Cleanup = () -> ()

type SpringState<T> = {
	goal: T,
	goalType: string,
	speed: number,
	damping: number,
	k: number, -- spring constant
	c: number, -- damping coefficient
	valueCount: number,
	completed: boolean?,

	pos: { number },
	target_pos: { number },
	vel: { number },

	onCompleteListeners: { [number]: (...any) -> (), n: number },
}

local createSourceNode = graph.createSourceNode
local updateDescendants = graph.updateDescendants
local capturing = graph.capturing

-- maps spring data to its corresponding output node
-- lifetime of spring data is tied to output node
local springs: { [SpringState<unknown>]: Node<unknown> } = setmetatable({} :: any, { __mode = "v" })

local VELOCITY_EPSILON = 1E-3
local POSITION_EPSILON = 1E-4

local UPDATE_RATE = 120

local TAU = 2 * math.pi

local function step_springs(dt: number)
	for spring in springs do
		local pos, vel, goal = spring.pos, spring.vel, spring.target_pos
		local completed = 0

		for i = 1, spring.valueCount do
			local p, v, g = pos[i], vel[i], goal[i]

			-- calculate displacement
			local dx = p - g

			local spring_force = dx * -spring.k
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

		if completed == spring.valueCount then
			spring.completed = true
		end
	end
end

local function update_spring_sources()
	for spring, output in springs do
		if spring.completed then
			output.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = spring.goal
			spring.completed = nil
			springs[spring] = nil

			if spring.onCompleteListeners.n > 0 then
				for _, listener in ipairs(spring.onCompleteListeners) do
					task.spawn(listener, output.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value)
				end
			end
		else
			output.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = convert[spring.goalType].pack(spring.pos)
		end

		updateDescendants(output)
	end
end

local function step()
	local accumulator, frame = 0, 0

	local max_delta = 1 / 5
	local fixed_rate = 1 / UPDATE_RATE

	return function(deltaTime: number)
		local steps = 0

		deltaTime = math.min(deltaTime, max_delta)
		accumulator += deltaTime

		if accumulator > 0 then
			steps = accumulator // fixed_rate
			frame += steps
			accumulator -= (steps * fixed_rate)
		end

		for _ = 1, steps do
			step_springs(fixed_rate)
		end

		update_spring_sources()
	end
end

local function is_spring(value: any): boolean
	local meta = getmetatable(value)
	return meta ~= nil and meta.type == "Spring"
end

local function spring<T>(source: Molecule<T>, speed: UsedAs<number>?, damping: UsedAs<number>?): Spring<T>
	local output = createSourceNode(nil :: T?)

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

	function self.onComplete(_, callback: (value: T) -> ()): Cleanup
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

	local is_under_root_scope = false
	local updates = -1
	local dispose
	local cleaned_up = false
	local cleanup = function()
		if cleaned_up then
			return
		end
		cleaned_up, is_under_root_scope = true, nil :: never
		updates = nil :: never

		if springs[state] then
			springs[state] = nil
		end

		table.clear(state)
		dispose()

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
					if capturing.n > 0 then
						local scope = capturing[capturing.n]

						if scope.type == nil then
							scope[output] = true
						elseif scope.type == "cleanup" and not is_under_root_scope then
							table.insert(scope, cleanup)
						end
					end

					return output.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value :: T
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

	if capturing.n > 0 and capturing[capturing.n].type == "root" then
		local scope = capturing[capturing.n]
		if not scope.already_queued[self] then
			is_under_root_scope = true
			scope.already_queued[self] = true
			table.insert(scope, cleanup)
		end
	end

	dispose = effect(function()
		local goal, _speed, _damping = source(), peek(speed or 1, true), peek(damping or 1, true)
		local changes = 0

		local goal_type = typeof(goal)

		updates += 1

		if state.damping ~= _damping then
			state.damping = _damping
			changes += 1
		end

		if state.speed ~= _speed then
			state.speed = _speed
			changes += 1
		end

		if state.goal ~= goal and goal == goal then
			state.goal = goal
			changes += 1
		end

		if state.goalType ~= goal_type then
			state.goalType = goal_type
			changes += 1
		end

		if changes > 0 then
			local oldValueCount = state.valueCount
			local data = convert[goal_type].unpack(goal) :: { number }
			state.valueCount = #data
			state.target_pos = data

			local n = (TAU / state.speed)
			local k = n * n
			local c = (4 * math.pi * state.damping) / state.speed
			state.k, state.c = k, c

			if updates == 0 then
				output.___DO_NOT_TOUCH_OR_YOU_WILL_GET_FIRED_usedAs_value = state.goal
				state.pos, state.vel = table.clone(state.target_pos), table.clone(state.target_pos)
			elseif updates > 0 and oldValueCount ~= state.valueCount then
				if oldValueCount > state.valueCount then
					local removals = oldValueCount - state.valueCount
					for _ = 1, removals do
						table.remove(state.pos)
						table.remove(state.vel)
					end
				elseif state.valueCount > oldValueCount then
					for i = oldValueCount + 1, state.valueCount do
						table.insert(state.pos, 0)
						table.insert(state.vel, 0)
					end
				end
			end

			springs[state] = output
		end
	end)

	return self :: any
end

return table.freeze {
	spring = spring,
	is_spring = is_spring,
	step = step,
}

local graph = require("@graph/")
local spring = require("@spring/")
local tween = require("@tween/")
local batch = require("@batch/")

local batched = graph.batched
local step_springs, update_spring_sources = spring.step()
local step_tweens, update_tween_sources = tween.step()

local UPDATE_RATE = 120

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

		if game then
			debug.profilebegin("TEISU SPRING")
		end

		for _ = 1, steps do
			step_springs(fixed_rate)
		end

		if game then
			debug.profileend()
		end

		if game then
			debug.profilebegin("TEISU TWEEN")
		end
		
		step_tweens(deltaTime)

		if game then
			debug.profileend()
		end

		local tween_sources, tween_source_count = update_tween_sources()
		local spring_sources, spring_source_count = update_spring_sources()

		local total = tween_source_count + spring_source_count

		if total > 0 then
			batch(function()
				for source_node, new_value in next, tween_sources do
					batched[source_node] = true
					source_node.isPartOfBatch = true
					source_node.cache = new_value
				end

				for source_node, new_value in next, spring_sources do
					batched[source_node] = true
					source_node.isPartOfBatch = true
					source_node.cache = new_value
				end
			end)
		end
	end
end

return table.freeze {
	spring = spring.spring,
	is_spring = spring.is_spring,

	tween = tween.tween,
	is_tween = tween.is_tween,

	step = step,
}

local graph = require("@graph/")
local spring = require("@spring/")
local tween = require("@tween/")
local batch = require("@batch/")

local update_descendants = graph.updateDescendants
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

		local tween_sources = update_tween_sources()
		local spring_sources = update_spring_sources()

		local total = #tween_sources + #spring_sources

		if total > 0 then
			batch(function()
				for _, source_node in  tween_sources do
					update_descendants(source_node)
				end

				for _, source_node in spring_sources do
					update_descendants(source_node)
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

-- Credit to Littensy: https://github.com/littensy/charm/blob/main/src/utils/setInterval.luau

local RunService = game:GetService("RunService")

local DEFAULT_UPDATE_RATE = (1 / 60) -- 60 Hz

type EmptyCallback = () -> ()

local function setInterval(onUpdate: (deltaTime: number) -> (), interval: number?): EmptyCallback
	local updateRate: number
	local connection: RBXScriptConnection

	if not interval then
		updateRate = DEFAULT_UPDATE_RATE
	else
		updateRate = interval
	end

	local accumulator = 0
	connection = RunService.PostSimulation:Connect(function(dt: number)
		accumulator += dt

		if accumulator >= updateRate then
			accumulator = 0

			onUpdate(updateRate)
		end
	end)

	return function()
		connection:Disconnect()
	end
end

return setInterval

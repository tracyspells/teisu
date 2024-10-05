--[=[
	Trigger a garbage collection cycle by allocating a large amount of junk memory
	and then waiting for the next frame.

	@param amount number
]=]
local function collect(amount: number?)
	for _ = 1, (amount or 3) do
		(collectgarbage :: any)("collect")
	end
end

return collect

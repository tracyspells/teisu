local types = require("@types/")
local effect = require("@effect/")
local peek = require("@peek/")

type Molecule<T> = types.Molecule<T>
type Cleanup = () -> ()
type Listener<T> = (T, T) -> ()
type NONE = types.NONE

local NONE = { __none = "__none" }

return function<T>(molecule: Molecule<T>, listener: Listener<T>): Cleanup
	local old: T | NONE = NONE :: any
	local disconnected = false

	local dispose = effect(function(_, on_change)
		local new = molecule()

		on_change(function()
			if disconnected then
				return
			end
			old = new
		end)

		if (old ~= NONE and new ~= NONE) and new ~= old then
			peek(function()
				listener(new, old :: T)
				return nil
			end)
		end
	end)

	return function()
		if disconnected then
			return
		end
		disconnected, old = true, nil :: never
		dispose()
	end
end

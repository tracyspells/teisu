local types = require("@types/")
local patch = require("@patch/")
local effect = require("@effect/")
local peek = require("@peek/")

type Molecule<T> = types.Molecule<T>
type Cleanup = () -> ()
type Listener<T> = (T, T) -> ()
type NONE = types.NONE

local NONE = patch.NONE
local is_none = patch.is_none

return function<T>(molecule: Molecule<T>, listener: Listener<T>): Cleanup
	return effect(function(_, old)
		local new = molecule()
	
		if not is_none(old) and old ~= new then
			peek(function()
				listener(new, old)
				return nil
			end)
		end

		return new
	end, NONE :: any)
end

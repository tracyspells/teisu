local types = require("./types")
local effect = require("./effect")

type Molecule<T> = types.Molecule<T>

type Node<T> = types.Node<T>

type Cleanup = () -> ()
type Listener<T> = (T, T) -> ()

local function subscribe<T>(molecule: Molecule<T>, listener: Listener<T>): Cleanup
	local old: T? = nil

	local dispose = effect(function()
		local new = molecule()

		old = if old == nil then new else old

		if new ~= old then
			local temp = old :: T
			old = new

			listener(new, temp)
		end
	end)

	return function()
		dispose()
		old = nil
	end
end

return subscribe

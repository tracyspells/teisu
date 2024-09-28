local types = require(script.Parent.types)
local effect = require(script.Parent.effect)

type Molecule<T> = types.Molecule<T>

type Node<T> = types.Node<T>

type Cleanup = () -> ()
type Listener<T> = (T, T) -> ()

local function subscribe<T>(molecule: Molecule<T>, listener: Listener<T>): Cleanup
	local old: T? = nil

	local dispose = effect(function()
		local new = molecule()

		old = if old == nil then new else old

		local the_same = new == old

		if not the_same then
			local temp = old :: T
			old = new

			listener(new, temp)
		end
	end)

	return dispose
end

return subscribe

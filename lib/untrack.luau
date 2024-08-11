local types = require(script.Parent.types)
local castTo = require(script.Parent.utils.castTo)

type UsedAs<T> = types.UsedAs<T>
type Node = types.Node

--[=[
    A helper function that removes dependencies of a computed object.
    
    @param target The computed object.
]=]
local function untrack<T>(target: UsedAs<T>)
	local targetComputed = castTo.computed(target)

	if targetComputed == nil then
		local targetValue = castTo.value(target)

		if targetValue == nil then
			error(`The argument you passed in 'untrack()' must be a Computed object, got {typeof(target)}`)
		else
			error("You cannot untrack a Value object!", 0)
		end
	else
		for parent in targetComputed.parents do
			if parent.children[targetComputed :: Node] == nil then
				continue
			end

			parent.children[targetComputed :: Node] = nil
		end
	end
end

return untrack

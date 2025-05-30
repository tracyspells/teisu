local cleanup = require("@cleanup/")

local metatable = table.freeze { type = "Action" }

local function is_action(obj: any): boolean
	return getmetatable(obj) == metatable
end

local function action(callback: (Instance) -> ())
	local a = { callback }
	setmetatable(a :: any, metatable)
	return table.freeze(a)
end

local function changed<T>(property: string, callback: (T) -> ())
	return action(function(instance)
		cleanup(instance:GetPropertyChangedSignal(property):Connect(function()
			callback((instance :: any)[property])
		end))

		callback((instance :: any)[property])
	end)
end

return table.freeze {
	action = action,
	is_action = is_action,

	changed = changed,
}

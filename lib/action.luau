local cleanup = require("@cleanup/")

local function is_action(obj: any): boolean
	local meta = getmetatable(obj)
	return meta ~= nil and meta.type == "Action"
end

local function action(callback: (Instance) -> ())
	local a = { callback }
	setmetatable(a :: any, table.freeze { type = "Action" })
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

local function input_began(callback: (InputObject) -> ())
	return action(function(instance)
		local gui_object = instance :: GuiObject

		cleanup(gui_object.InputBegan:Connect(callback))
	end)
end

local function input_changed(callback: (InputObject) -> ())
	return action(function(instance)
		local gui_object = instance :: GuiObject

		cleanup(gui_object.InputChanged:Connect(callback))
	end)
end

local function input_ended(callback: (InputObject) -> ())
	return action(function(instance)
		local gui_object = instance :: GuiObject

		cleanup(gui_object.InputEnded:Connect(callback))
	end)
end

return table.freeze {
	action = action,
	is_action = is_action,

	changed = changed,
	input_began = input_began,
	input_changed = input_changed,
	input_ended = input_ended,
}

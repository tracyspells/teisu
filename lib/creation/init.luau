local typeof = game and typeof or require("@mock/").typeof
local Instance = game and Instance or require("@mock/").Instance

local types = require("@types/")
local graph = require("@graph/")
local defaults = require("@defaults/")
local apply = require("@apply/")
local cleanup = require("@cleanup/")

type Map<K, V> = types.Map<K, V>
type Cleanup = types.Cleanup
type Props = Map<any, any>
type RootScope = graph.RootScope

local push_scope = graph.push_scope
local remove_scope = graph.remove_scope

local ctor_cache = setmetatable({} :: { [string]: () -> Instance }, {
	__index = function(self, class: string)
		local ok, instance: Instance = pcall(Instance.new, class)
		if not ok then
			error(`invalid class name, couldn't create instance of class {class}`)
		end

		local default: { [string]: any }? = defaults[class]

		if default then
			for i, v in next, default do
				(instance :: any)[i] = v
			end
		end

		local function ctor(props: Props): Instance
			return apply(instance:Clone(), props)
		end

		self[class] = ctor
		return ctor
	end,
})

local function create_instance(class: string)
	return ctor_cache[class]
end

local function clone_instance(instance: Instance)
	return function(properties: Props): Instance
		local clone = instance:Clone()
		if not clone then
			error("attempt to clone a non-archivable instance")
		end
		return apply(clone, properties)
	end
end

local function new(class_or_instance: string | Instance, props: Props?): ((Props) -> Instance) | Instance
	local result: (Props) -> Instance
	if type(class_or_instance) == "string" then
		result = create_instance(class_or_instance)
	elseif typeof(class_or_instance) == "Instance" then
		result = clone_instance(class_or_instance)
	else
		error("bad argument #1, expected string or instance, got " .. typeof(class_or_instance), 0)
		return nil :: never
	end

	if props then
		return result(props)
	end

	return result
end

local function root<T...>(fn: () -> T...): (Cleanup, T...)
	local scope = {
		type = "root",
		already_queued = {},
		n = 0,
	} :: RootScope
	
	local destroyed = false
	local destroy = function()
		if destroyed then
			error(`root already destroyed`)
		end

		if scope.n > 0 then
			for i = scope.n, 1, -1 do
				local fn = scope[i]
				if not fn then
					continue
				end
				fn()
			end
		end
		
		table.clear(scope)
		destroyed = true
	end

	local index = push_scope(scope)
	local result = { xpcall(fn, debug.traceback) }

	remove_scope(index)

	if not result[1] then
		destroy()
		error(`error while running root():\n\n{result[2]}`, 0)
	end

	return destroy, unpack(result :: any, 2)
end

local function mount<T>(component: () -> T, target: Instance?): () -> ()
	return root(function()
		local result = component()
		if target then
			apply(target, { result })
		end
	end)
end

type Create<Name, Instance> = ((Name, Props) -> Instance) & ((Name) -> (Props) -> Instance)

local new_types = (new :: any) :: 
	& (<T>(T & Instance) -> (Props) -> T) 
	& (<T>(T & Instance, Props) -> T) 
	& Create<"Folder", Folder> 
	& Create<"BillboardGui", BillboardGui> 
	& Create<"CanvasGroup", CanvasGroup> 
	& Create<"Frame", Frame> 
	& Create<"ImageButton", ImageButton> 
	& Create<"ImageLabel", ImageLabel> 
	& Create<"ScreenGui", ScreenGui> 
	& Create<"ScrollingFrame", ScrollingFrame> 
	& Create<"SurfaceGui", SurfaceGui> 
	& Create<"TextBox", TextBox> 
	& Create<"TextButton", TextButton> 
	& Create<"TextLabel", TextLabel> 
	& Create<"UIAspectRatioConstraint", UIAspectRatioConstraint> 
	& Create<"UICorner", UICorner> 
	& Create<"UIGradient", UIGradient> 
	& Create<"UIGridLayout", UIGridLayout> 
	& Create<"UIListLayout", UIListLayout> 
	& Create<"UIPadding", UIPadding> 
	& Create<"UIPageLayout", UIPageLayout> 
	& Create<"UIScale", UIScale> 
	& Create<"UISizeConstraint", UISizeConstraint> 
	& Create<"UIStroke", UIStroke> 
	& Create<"UITableLayout", UITableLayout> 
	& Create<"UITextSizeConstraint",UITextSizeConstraint> 
	& Create<"VideoFrame", VideoFrame> 
	& Create<"ViewportFrame", ViewportFrame> 
	& Create<string, Instance>

return table.freeze {
	defaults = defaults,
	root = root,
	mount = mount,
	new = new_types,
	apply = apply,
	cleanup = cleanup,
}

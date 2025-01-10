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
        if not clone then error "attempt to clone a non-archivable instance" end
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

local function root(fn: () -> ()): Cleanup
	local scope = { 
        type = "root", 
        already_queued = {}
     } :: { [number]: Cleanup, type: "root", already_queued: { [any]: true } }
	local index = push_scope(scope)

	local destroyed = false
	local destroy = function()
		if destroyed then
			error(`root already destroyed`)
		end

		local cleanups = table.clone(scope)
		cleanups.type, cleanups.already_queued = nil :: never, nil :: never
		
		table.clear(scope)
		
		for index = #cleanups, 1, -1 do
			local fn = cleanups[index]
			if not fn then continue end
			fn()
		end

		destroyed = true
	end

	local ok, message: string? = xpcall(fn, debug.traceback)

	remove_scope(index)

	if not ok then
		destroy()
		error(`error while running root():\n\n{message}`, 0)
	end

	return destroy
end

local function mount<T>(component: () -> T, target: Instance?): () -> ()
    return root(function()
        local result = component()
        if target then apply(target, { result }) end
    end)
end

return table.freeze({
    defaults = defaults,
	root = root,
    mount = mount,
    new = new,
    apply = apply,
    cleanup = cleanup,
})

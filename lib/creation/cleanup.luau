local typeof = game and typeof or require("@mock/").typeof

local types = require("@types/")
local spring = require("@spring/")
local tween = require("@tween/")
local graph = require("@graph/")

type Spring<T> = types.Spring<T>

type Destroyable = { destroy: (any) -> () } | { Destroy: (any) -> () }
type Disconnectable = { disconnect: (any) -> () } | { Disconnect: (any) -> () }

local is_spring, is_tween = spring.is_spring, tween.is_tween
local push_scope = graph.push_scope
local remove_scope = graph.remove_scope
local get_root_scope = graph.get_root_scope
local push_to_root_scope = graph.push_to_root_scope

local function get_cleanup(obj: any): () -> ()
	return if typeof(obj) == "RBXScriptConnection"
		then function()
			obj:Disconnect()
		end
		elseif type(obj) == "thread" then function()
			task.cancel(obj)
		end
		elseif typeof(obj) == "Instance" then function()
			obj:Destroy()
		end
		elseif is_spring(obj) or is_tween(obj) then function()
			obj()
		end
		elseif obj.destroy then function()
			obj:destroy()
		end
		elseif obj.disconnect then function()
			obj:disconnect()
		end
		elseif obj.Destroy then function()
			obj:Destroy()
		end
		elseif obj.Disconnect then function()
			obj:Disconnect()
		end
		else error("cannot cleanup given object")
end

local function do_cleanup(fn: () -> ())
	local cleanup_scope = { type = "cleanup" } :: { [number]: () -> (), type: "cleanup" }
	local index = push_scope(cleanup_scope)

	fn()

	remove_scope(index)

	if cleanup_scope[1] ~= nil then
		cleanup_scope[1]()
	end

	table.clear(cleanup_scope)
end

local function cleanup(object: any)
	local scope = get_root_scope()
	local fn = type(object) == "function" and object :: () -> () or get_cleanup(object)

	if not scope then
		return do_cleanup(fn)
	end

	push_to_root_scope(scope, object, fn)
end

return cleanup :: ((callback: () -> ()) -> ()) & ((thread: thread) -> ()) & ((instance: Destroyable) -> ()) & ((connection: Disconnectable) -> ()) & ((instance: Instance) -> ()) & ((connection: RBXScriptConnection) -> ())

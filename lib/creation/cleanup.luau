local typeof = game and typeof or require("@mock/").typeof

local types = require("@types/")
local spring = require("@spring/")
local graph = require("@graph/")

type Spring<T> = types.Spring<T>

type Destroyable = { destroy: (any) -> () } | { Destroy: (any) -> () }
type Disconnectable = { disconnect: (any) -> () } | { Disconnect: (any) -> () }

local capturing = graph.capturing
local is_spring = spring.is_spring
local push_scope = graph.push_scope
local remove_scope = graph.remove_scope

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
		elseif is_spring(obj) then function()
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
	local scope = capturing.n > 0 and capturing[capturing.n] or nil
	local is_scope_stable = scope ~= nil and scope.type == "root" and scope.already_queued ~= nil
	local fn = type(object) == "function" and object :: () -> () or get_cleanup(object)

	if not is_scope_stable then
		return do_cleanup(fn)
	end

	local stable_scope: graph.Scope = scope :: any
	if not stable_scope.already_queued[object] then
		stable_scope.already_queued[object] = true
		table.insert(stable_scope, fn)
	end

	return
end

return cleanup :: ((callback: () -> ()) -> ()) & ((thread: thread) -> ()) & ((instance: Destroyable) -> ()) & ((connection: Disconnectable) -> ()) & ((instance: Instance) -> ()) & ((connection: RBXScriptConnection) -> ())

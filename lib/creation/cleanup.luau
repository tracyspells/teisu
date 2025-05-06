local typeof = game and typeof or require("@mock/").typeof

local types = require("@types/")
local spring = require("@spring/")
local tween = require("@tween/")
local graph = require("@graph/")

type Task = types.Task

local is_spring, is_tween = spring.is_spring, tween.is_tween
local get_scope = graph.get_scope
local new_scope = graph.new_scope
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local push_cleanup = graph.push_cleanup
local flush_cleanups = graph.flush_cleanups

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
	local scope = new_scope(nil, "cleanup")

	push_scope(scope)

	fn()
	
	pop_scope()
	flush_cleanups(scope)
end

return function(object: Task)
	local scope = get_scope()
	local fn = type(object) == "function" and object :: () -> () or get_cleanup(object)

	if not scope then
		return do_cleanup(fn)
	end

	push_cleanup(scope, fn, object)
end

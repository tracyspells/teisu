local types = require("@types/")
local graph = require("@graph/")
local patch = require("@patch/")

type Context<T> = types.Context<T>

local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local get_scope = graph.get_scope
local new_scope = graph.new_scope
local flush_captures = graph.flush_captures
local set_context = graph.set_context
local is_none = patch.is_none

local ids = 0

local function create<T>(...: T): Context<T>
    ids += 1
    local context_id = ids

    local context = {}
    local default_value = if select("#", ...) == 0 then patch.NONE else ...

    context.provide = function<V>(value: T, callback: () -> V)
        local owner = get_scope()
        if owner == nil then error(`attempt to set context outside of a scope`) end
        
        local scope = new_scope(owner)
        set_context(scope, context_id, if value == nil then patch.NONE else value)

        push_scope(scope)
        local on_error = function(msg: string) return debug.traceback(msg, 3) end
        local ok, result = xpcall(callback, on_error)
        pop_scope()
        flush_captures(scope)

        if not ok then
            error(`error while running context:\n\n{result}`, 0)
        end

        return result
    end

    context.consume = function(): T
        local owner = get_scope()
        if owner == nil then error(`attempt to get context value outside of a scope`) end
        
        local scope: (graph.Scope | false) = owner

        while scope do
            local contexts = scope.contexts

            if contexts == false then
                scope = scope.owner
                continue
            end

            local value = (contexts :: { unknown })[context_id]

            if value == nil then
                scope = scope.owner
                continue
            end

            return if is_none(value) then nil :: any else value
        end

        if is_none(default_value) then
            return nil :: any
        end

        return default_value :: T
    end

    return table.freeze(context)
end

return create

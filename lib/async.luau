local task = if game then task else require("@mock/").task
local types = require("@types/")
local graph = require("@graph/")

type Molecule<T> = types.Molecule<T>
type Node<T> = types.Node<T>

local evaluate = graph.evaluate
local create_source_node = graph.createSourceNode
local create_derived_node = graph.createDerivedNode
local get_scope = graph.get_scope
local new_scope = graph.new_scope
local push_scope = graph.push_scope
local pop_scope = graph.pop_scope
local push_child_to_scope = graph.push_child_to_scope
local destroy_scope = graph.destroy_scope
local push_cleanup = graph.push_cleanup
local flush_captures = graph.flush_captures
local update_descendants = graph.updateDescendants
local depend, unparent = graph.depend, graph.unparent
local try = graph.try

local function async<T>(fallback: T, processor: (set: (T) -> ()) -> T): Molecule<T>
	local reactive_node: Node<any>
	local value: Node<T> = create_source_node(fallback)

	local owner = get_scope()
	local curr_thread: thread?
	local inner_scope: graph.Scope?
	local cleaned_up = false

	local function set(new: T)
		if cleaned_up then return end

		value.cache = new
		update_descendants(value)
	end

	local function destroy()
		if not cleaned_up then
			cleaned_up = true

			unparent(reactive_node)

			if curr_thread ~= nil then
				task.cancel(curr_thread)
				curr_thread = nil
			end

			if inner_scope then
				destroy_scope(inner_scope)
				inner_scope = nil
			end
		end
	end

	local function update()
		assert(reactive_node, "reactive node does not exist")

		if curr_thread ~= nil then
			task.cancel(curr_thread)
			curr_thread = nil
		end

		curr_thread = task.spawn(function()
			if inner_scope ~= nil then
				destroy_scope(inner_scope)
				inner_scope = nil
			end

            local scope = new_scope(owner)
            local function runner(): T
                local new_value = processor(set)

                if scope.effect_captures ~= false then
                    return error(`cannot run an effect inside a computed`)
                end

                return new_value
            end

			push_scope(scope)
			local result = try(
                runner, 
                function() pop_scope() end, 
                function() destroy_scope(scope); set(fallback) end
            )

			inner_scope = scope
            
			depend(scope, reactive_node)
			flush_captures(scope)
			set(result)
		end)

		return true
	end

	reactive_node = create_derived_node(update)

    if owner then
		push_cleanup(owner, destroy, reactive_node)
	end

	return function(...: any)
		if select("#", ...) == 0 then
			local scope = get_scope()

			if scope then
				if scope.type == "cleanup" and not owner then
					return push_cleanup(scope, destroy, value) :: never
				end
			end

			if not cleaned_up then
				evaluate(reactive_node)
			end

			if scope then
				push_child_to_scope(scope, value)
			end

			return value.cache :: T
		end

		local target = ...

		if target ~= graph.NODE_KEY then
			return nil :: never
		end

		return value :: never
	end
end

return async

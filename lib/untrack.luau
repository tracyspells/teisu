local types = require(script.Parent.types)
local castToState = require(script.Parent.utils.castToState)

type Computed<T> = types.Computed<T>
type UsedAs<T> = types.UsedAs<T>

local function castToComputed<T>(target: UsedAs<T>): Computed<T>?
    local targetState = castToState(target)
    if targetState ~= nil and targetState.implements.computed == true then
        return targetState :: Computed<T>
    end

    return nil
end

--[=[
    A helper function that removes dependencies of a read-only value.
    
    @param target The read-only value.
]=]
local function untrack<T>(target: Computed<T> | T)
    local targetComputed = castToComputed(target)

    if targetComputed == nil then
        local targetState = castToState(target)

        if targetState ~= nil and targetState.implements.state == true then
            error("You cannot untrack a State object!", 0)

            return
        else
            error(`The argument you passed in 'untrack()' must be a Computed object, got {typeof(target)}`)
            
            return
        end
    end

    for parent in targetComputed.parents do
        if parent.children[targetComputed] == nil then
            continue
        end

        parent.children[targetComputed] = nil
    end
end

return untrack

local types = require(script.Parent.types)
local updateAll = require(script.Parent.graph.updateAll)
local validateResult = require(script.Parent.utils.validateResult)

type Value<T> = types.Value<T>

type Node = types.Node

type Self<T> = Node & Value<T> & {
	_equals: ((new: T, old: T) -> boolean)?,
}

type Options<T> = {
	equals: ((new: T, old: T) -> boolean)?,
}

local class = {}
class.implements = table.freeze({ node = true, value = true })
class.parents = table.freeze({})
class.timeliness = "lazy"

local METATABLE = table.freeze({ __index = class })

--[=[
	Creates a new value with the given state.
	
	@param value The initial state.
	@param options Optional configuration.
	@return A new value
]=]
local function value<T>(value: T, options: Options<T>?): Value<T>
	assert(validateResult(true, "value", value, "object"))

	local self: Self<T> = setmetatable({
		createdAt = os.clock(),
		children = {},
		state = "clean",
		version = 0,
		_value = value,
		_initialValue = value,
		_equals = options and options.equals,
	}, METATABLE) :: any

	return self
end

function class._evaluate<T>(_: Self<T>)
	-- The validation check in ':set()' is done in advance when the value is set, so this
	-- should be fine.

	return true
end

function class.reset<T>(self: Self<T>)
	self:set(self._initialValue :: any)
end

function class.set<T>(self: Self<T>, setTo: T | ((T) -> T))
	local oldState = self._value
	local newState

	if typeof(setTo) ~= "function" then
		newState = setTo :: T
	else
		newState = setTo(oldState)
	end

	if newState ~= oldState and not (self._equals and self._equals(newState, oldState)) then
		self._value = newState
		updateAll(self)
	end
end

table.freeze(class)
return value

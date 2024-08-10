local types = require(script.Parent.types)

local depend = require(script.Parent.graph.depend)
local castToState = require(script.Parent.utils.castToState)
local peek = require(script.Parent.peek)
local validateResult = require(script.Parent.utils.validateResult)

type Computed<T> = types.Computed<T>

type Set<T> = types.Set<T>
type Dictionary<K, V> = types.Dictionary<K, V>

type Node = types.Node

type Use = types.Use
type UsedAs<T> = types.UsedAs<T>

local function use<T>(self: Computed<T>): Use
	return function<T>(subject: UsedAs<T>): T
		local targetState = castToState(subject)

		if targetState ~= nil then
			depend(self, targetState)
		end

		return peek(subject)
	end :: Use
end

local class = {}
class.implements = table.freeze({ node = true, computed = true })
class.timeliness = "lazy"

local METATABLE = table.freeze({ __index = class })

--[=[
	Returns a read-only value that derives its state from one or more values.

	@param callback The function that produces a new stae.
	@return A read-only value.
]=]
local function computed<T>(callback: (use: Use) -> T): Computed<T>
	local self: Computed<T> = setmetatable({
		createdAt = os.clock(),
		children = {},
		parents = {},
		state = "dirty",
		version = 0,
		_value = nil,
		_processor = callback,
	}, METATABLE) :: any

	return self
end

function class._evaluate<T>(self: Computed<T>): boolean
	local previousValue = self._value
	local success, result = pcall(self._processor, use(self))

	if success then
		local ok, err = validateResult(true, "computed", result, "calculation")

		if not ok then
			print(err)

			return false
		end

		local isSimilar = (previousValue == result)

		if not isSimilar then
			self._value = result
		end

		return not isSimilar
	else
		print(result)

		return false
	end
end

table.freeze(class)
return computed

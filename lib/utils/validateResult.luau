local ACCEPTABLE_TYPES = { "string", "number", "boolean", "table" }

type IdentifierMessage = "value" | "computed" | "focused" | "Value" | "Computed" | "Focused"

local function validateResult<T>(
	showErrorMessage: boolean?,
	identifier: IdentifierMessage,
	result: T,
	additionalMessage: string?
): (boolean, string?)
	if result ~= nil then
		if
			typeof(result) ~= "string"
			and typeof(result) ~= "boolean"
			and typeof(result) ~= "number"
			and typeof(result) ~= "table"
		then
			return false,
				if showErrorMessage
					then `this {identifier}{if additionalMessage then " " .. additionalMessage else ""} must be one of the following types: {table.concat(
						ACCEPTABLE_TYPES, ", "
					)}\n(got {typeof(result)}).`
					else nil
		end

		if typeof(result) == "number" then
			if result ~= result then
				return false,
					if showErrorMessage
						then `this {identifier}{if additionalMessage then " " .. additionalMessage else ""} cannot be NaN.`
						else nil
			elseif result == math.huge or result == -math.huge then
				return false,
					if showErrorMessage
						then `this {identifier}{if additionalMessage then " " .. additionalMessage else ""} cannot be infinity.`
						else nil
			end
		end

		if typeof(result) == "table" and getmetatable(result) ~= nil then
			return false,
				if showErrorMessage
					then `this {identifier}{if additionalMessage then " " .. additionalMessage else ""} cannot be a metatable.`
					else nil
		end
	end

	return true
end

return validateResult

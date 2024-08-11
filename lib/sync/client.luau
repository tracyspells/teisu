-- Credits go to Littensy: https://github.com/littensy/charm/blob/main/src/sync/client.luau

local RunService = game:GetService("RunService")

local types = require(script.Parent.Parent.types)
local peek = require(script.Parent.Parent.peek)

local deltaTable = require(script.Parent.deltaTable)
local isStrictTable = require(script.Parent.Parent.utils.isStrictTable)

type NetworkPayload = types.NetworkPayload

type ClientSyncer = types.ClientSyncer
type ClientOptions = types.ClientOptions

local apply = deltaTable.apply

local IS_CLIENT = RunService:IsClient()
local IS_TESTING = RunService:IsStudio() and RunService:IsRunning()

local ERROR_MESSAGES = {
	Initialize = "'sync.client()' must be called from the client!",
	Values = [[
        The 'value' key in 'options' configuration must be a map of values!
        (i.e. { [string]: Value<any> })
    ]],
}

local function client(options: ClientOptions): ClientSyncer
	if not IS_TESTING and not IS_CLIENT then
		error(ERROR_MESSAGES.Initialize)
	end

	if not isStrictTable(options) then
		error(`The 'options' argument must be a table, got {typeof(options)}`)
	end

	if not isStrictTable(options.values) then
		error(ERROR_MESSAGES.Values)
	end

	local self = {} :: ClientSyncer
	local values = options.values

	function self:sync(...: NetworkPayload)
		for index = 1, select("#", ...) do
			local payload: NetworkPayload = select(index, ...)

			for key, contents in payload.contents do
				if payload.type == "diff" then
					local base = peek(values[key])
					local result = apply(base, contents)

					values[key]:set(result)
				else
					values[key]:set(contents)
				end
			end
		end
	end

	return self
end

return client

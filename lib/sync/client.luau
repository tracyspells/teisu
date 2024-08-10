local RunService = game:GetService("RunService")

local types = require(script.Parent.Parent.types)
local peek = require(script.Parent.Parent.peek)

local utils = script.Parent.Parent.utils
local deltaTable = require(utils.deltaTable)
local isStrictTable = require(utils.isStrictTable)

local IS_CLIENT = RunService:IsClient()
local IS_TESTING = RunService:IsStudio() and RunService:IsRunning()

local ERROR_MESSAGES = {
	Initialize = "'sync.client()' must be called from the client!",
	States = [[
        The 'states' argument in 'sync.client()' must be a map of states!
        (i.e. { [string]: State<any> })
    ]],
}

type ClientSyncer = types.ClientSyncer
type ClientOptions = {
	values: ValuesMap 
}

type NetworkPayload = types.NetworkPayload

type ValuesMap = Dictionary<string, types.Value<any>>

type Dictionary<K, V> = types.Dictionary<K, V>

local function client(options: ClientOptions): ClientSyncer
	if not isStrictTable(options.values) then
		error(ERROR_MESSAGES.States)
	end

	if not IS_TESTING and not IS_CLIENT then
		error(ERROR_MESSAGES.Initialize)
	end

	local self = {} :: ClientSyncer
	local values = options.values

	function self:sync(...: NetworkPayload)
		for index = 1, select("#", ...) do
			local payload: NetworkPayload = select(index, ...)

			for key, contents in payload.contents do
				if payload.type == "diff" then
					values[key]:set(deltaTable.apply(peek(values[key]), contents))
				else
					values[key]:set(contents)	
				end
			end
		end
	end

	return self
end

return client

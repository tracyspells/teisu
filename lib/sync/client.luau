local types = require("@types/")
local patch = require("@patch/")
local batch = require("@batch/")

type Flec<T> = types.Flec<T>

type Patch<K, V> = types.Patch<K, V>
type SyncPayload = types.SyncPayload

export type Options = {
	flecs: { [string | number]: Flec<any> },
}

type Client = {
	sync: (self: Client, payload: SyncPayload) -> (),
}

local apply = patch.apply

return function(options: Options): Client
	local self = {} :: Client

	local hydrated = false
	local function hydrate(data: { [string | number]: any })
		for key, value in next, data do
			local flec = options.flecs[key]
			if flec == nil then
				continue
			end

			flec(value)
		end

		hydrated = true
	end

	local function sync(patches: { Patch<string | number, any> })
		local target = {}

		for key, flec in next, options.flecs do
			target[key] = flec()
		end

		target = apply(target, patches)

		for key, flec in next, options.flecs do
			flec(target[key])
		end
	end

	function self:sync(payload)
		batch(function()
			if payload.type == "init" then
				hydrate(payload.data)
			elseif hydrated then
				sync(payload.data)
			end
		end)
	end

	return self
end

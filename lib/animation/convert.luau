--!native

local Vector2 = game and Vector2 or require("@mock/").Vector2
local Vector3 = game and Vector3 or require("@mock/").Vector3

local lab = require("@lab/")

type TypeToList<T> = (T) -> { number }
type ListToType<T> = ({ number }) -> T

local toLab, fromLab = lab.to, lab.from

-- i would add a @native tag here
-- but it's gonna screw up unit tests
-- more specifically, mlua doesn't recognize @native
local function pack_cframe(v: { number }): ListToType<CFrame>
	local cos_x = math.cos(v[4] * 0.5)
	local sin_x = math.sin(v[4] * 0.5)
	local cos_y = math.cos(v[5] * 0.5)
	local sin_y = math.sin(v[5] * 0.5)
	local cos_z = math.cos(v[6] * 0.5)
	local sin_z = math.sin(v[6] * 0.5)

	return CFrame.new(
		v[1],
		v[2],
		v[3],
		sin_x * cos_y * cos_z + cos_x * sin_y * sin_z, -- qX
		cos_x * sin_y * cos_z - sin_x * cos_y * sin_z, -- qY
		cos_x * cos_y * sin_z + sin_x * sin_y * cos_z, -- qZ
		cos_x * cos_y * cos_z - sin_x * sin_y * sin_z -- qW
	) :: any
end

local type_conversions = {
	number = {
		unpack = function(v)
			return { v }
		end :: TypeToList<number>,

		pack = function(v)
			return v[1]
		end :: ListToType<number>,
	},

	boolean = {
		unpack = function(v)
			return { v and 1 or 0 }
		end :: TypeToList<boolean>,

		pack = function(v)
			return v[1] >= 0.5
		end :: ListToType<boolean>,
	},

	UDim = {
		unpack = function(v)
			return { v.Scale, v.Offset }
		end :: TypeToList<UDim>,

		pack = function(v)
			return UDim.new(v[1], math.round(v[2]))
		end :: ListToType<UDim>,
	},

	UDim2 = {
		unpack = function(v)
			return { v.X.Scale, v.X.Offset, v.Y.Scale, v.Y.Offset }
		end :: TypeToList<UDim2>,

		pack = function(v)
			return UDim2.new(v[1], math.round(v[2]), v[3], math.round(v[4]))
		end :: ListToType<UDim2>,
	},

	Rect = {
		unpack = function(v)
			return { v.Min.X, v.Min.Y, v.Max.X, v.Max.Y }
		end :: TypeToList<Rect>,

		pack = function(v)
			return Rect.new(v[1], v[2], v[3], v[4])
		end :: ListToType<Rect>,
	},

	Vector2 = {
		unpack = function(v)
			return { v.X, v.Y }
		end :: TypeToList<Vector2>,

		pack = function(v)
			return Vector2.new(v[1], v[2])
		end :: ListToType<Vector2>,
	},

	Vector3 = {
		unpack = function(v)
			return { v.X, v.Y, v.Z }
		end :: TypeToList<Vector3>,

		pack = function(v)
			return Vector3.new(v[1], v[2], v[3])
		end :: ListToType<Vector3>,
	},

	Color3 = {
		unpack = function(v)
			local lab = toLab(v)
			return { lab.L, lab.A, lab.B }
		end :: TypeToList<Color3>,

		pack = function(v)
			return fromLab { L = v[1], A = v[2], B = v[3] }
		end :: ListToType<Color3>,
	},

	NumberRange = {
		unpack = function(v)
			return { v.Min, v.Max }
		end :: TypeToList<NumberRange>,

		pack = function(v)
			return NumberRange.new(v[1], v[2])
		end :: ListToType<NumberRange>,
	},

	ColorSequenceKeypoint = {
		unpack = function(v)
			local lab = toLab(v.Value)
			return { lab.L, lab.A, lab.B, v.Time }
		end :: TypeToList<ColorSequenceKeypoint>,

		pack = function(v)
			return ColorSequenceKeypoint.new(v[4], fromLab { L = v[1], A = v[2], B = v[3] })
		end :: ListToType<ColorSequenceKeypoint>,
	},

	NumberSequenceKeypoint = {
		unpack = function(v)
			return { v.Value, v.Time, v.Envelope }
		end :: TypeToList<NumberSequenceKeypoint>,

		pack = function(v)
			return NumberSequenceKeypoint.new(v[2], v[1], v[3])
		end :: ListToType<NumberSequenceKeypoint>,
	},

	CFrame = {
		unpack = function(v)
			local rotX, rotY, rotZ = v:ToEulerAnglesXYZ()
			return { v.X, v.Y, v.Z, rotX, rotY, rotZ }
		end :: TypeToList<CFrame>,

		pack = pack_cframe,
	},
}

setmetatable(type_conversions, {
	__index = function(_, t: string)
		error(`cannot animate type {t}`, 0)
	end,
})

return type_conversions

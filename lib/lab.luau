-- https://github.com/cxmeel/colour-utils/tree/default/src/LAB

local Color3 = game and Color3 or require("@mock/").Color3

local types = require("@types/")

type LAB = types.LAB

local X_N = 0.950470
local Y_N = 1
local Z_N = 1.088830

local T0 = 0.137931034
local T1 = 0.206896552
local T2 = 0.12841855
local T3 = 0.008856452

local ONE_THIRD = 1 / 3
local ONE_ONE_HUNDRED_SIXTEEN = 1 / 116
local ONE_FIVE_HUNDRED = 1 / 500
local ONE_TWO_HUNDRED = 1 / 200
local ONE_TWO_POINT_FOUR = 1 / 2.4

local function XYZ_RGB(value: number): number
	return 255 * (if value <= 0.00304 then 12.92 * value else 1.055 * value ^ ONE_TWO_POINT_FOUR - 0.055)
end

local function LAB_XYZ(value: number): number
	return if value > T1 then (value * value * value) else T2 * (value - T0)
end

local function RGB_XYZ(value: number): number
	if value <= 0.04045 then
		return value * 0.0773993808
	end

	return ((value + 0.055) * 0.947867299) ^ 2.4
end

local function XYZ_LAB(value: number): number
	if value > T3 then
		return value ^ ONE_THIRD
	end

	return value / T2 + T0
end

local function toLab(color: Color3): LAB
	local r = RGB_XYZ(color.R)
	local g = RGB_XYZ(color.G)
	local b = RGB_XYZ(color.B)

	local x = XYZ_LAB((0.4124564 * r + 0.3575761 * g + 0.1804375 * b) / X_N)
	local y = XYZ_LAB((0.2126729 * r + 0.7151522 * g + 0.0721750 * b) / Y_N)
	local z = XYZ_LAB((0.0193339 * r + 0.1191920 * g + 0.9503041 * b) / Z_N)

	local l = 116 * y - 16

	return { L = l < 0 and 0 or l, A = 500 * (x - y), B = 200 * (y - z) }
end

local function fromLab(lab: LAB): Color3
	local y = (lab.L + 16) * ONE_ONE_HUNDRED_SIXTEEN
	local x = lab.A ~= lab.A and y or y + lab.A * ONE_FIVE_HUNDRED
	local z = lab.B ~= lab.B and y or y - lab.B * ONE_TWO_HUNDRED
	y = Y_N * LAB_XYZ(y)
	x = X_N * LAB_XYZ(x)
	z = Z_N * LAB_XYZ(z)

	local r = XYZ_RGB(3.2404542 * x - 1.5371385 * y - 0.4985314 * z)
	local g = XYZ_RGB(-0.9692660 * x + 1.8760108 * y + 0.0415560 * z)
	local b = XYZ_RGB(0.0556434 * x - 0.2040259 * y + 1.0572252 * z)

	return Color3.fromRGB(r, g, b)
end

local function lerp(from: Color3, to: Color3, blend: number): Color3
	local a = toLab(from)
	local b = toLab(to)

	local L = a.L + (b.L - a.L) * blend
	local A = a.A + (b.A - a.A) * blend
	local B = a.B + (b.B - a.B) * blend

	return fromLab { L = L, A = A, B = B }
end

return table.freeze {
	from = fromLab,
	to = toLab,
	lerp = lerp,
}

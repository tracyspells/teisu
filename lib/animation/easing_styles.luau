--!native

local PI = math.pi
local TAU = PI * 2
local HALF_PI = PI * 0.5

local function linear(x: number)
	return x
end

local function smooth(x: number)
	local times_two = 2 * x
	local power_of_two = x * x

	return power_of_two * (3 - times_two)
end

local function in_sine(x: number)
	return 1 - math.cos(x * HALF_PI)
end

local function out_sine(x: number)
	return math.sin(x * HALF_PI)
end

local function in_out_sine(x: number)
	return (1 - math.cos(PI * x)) * 0.5
end

local function in_quad(x: number)
	return x * x
end

local function out_quad(x: number)
	local a = (1 - x)
	return 1 - (a * a)
end

local function in_out_quad(x: number)
	if x < 0.5 then
		return 2 * in_quad(x)
	end

	local a = -2 * x + 2
	local power_of_two = a * a
	
	return 1 - power_of_two * 0.5
end

local function in_cubic(x: number)
	return x * x * x
end

local function out_cubic(x: number)
	return 1 - in_cubic(1 - x)
end

local function in_out_cubic(x: number)
	if x < 0.5 then
		return 4 * in_cubic(x)
	end

	local a = -2 * x + 2
	a = in_cubic(a)

	return 1 - a * 0.5
end

local function in_quart(x: number)
	return x * x * x * x
end

local function out_quart(x: number)
	return 1 - in_quart(1 - x)
end

local function in_out_quart(x: number)
	if x < 0.5 then
		return 8 * in_quart(x)
	end

	local a = -2 * x + 2
	a = in_quart(a)

	return 1 - a * 0.5
end

local function in_quint(x: number)
	return x * x * x * x * x
end

local function out_quint(x: number)
	return 1 - in_quad(1 - x)
end

local function in_out_quint(x: number)
	if x < 0.5 then
		return 16 * in_quint(x)
	end

	local a = -2 * x + 2
	a = in_quint(a)

	return 1 - a * 0.5
end

local function in_exponential(x: number)
	return if x == 0 then 0 else math.pow(2, 10 * x - 10)
end

local function out_exponential(x: number)
	if x == 1 then
		return 1
	end

	return 1 - math.pow(2, -10 * x)
end

local function in_out_exponential(x: number)
    if x == 0 then
        return 0
    end

    if x == 1 then
        return 1
    end

    if x < 0.5 then
        return math.pow(2, 20 * x - 10) * 0.5
    end

    return (2 - math.pow(2, -20 * x + 10)) * 0.5
end

local function in_circular(x: number)
    local power_of_two = x * x

    return 1 - math.sqrt(1 - power_of_two)
end

local function out_circular(x: number)
    local minus_one = x - 1
    local power_of_two = minus_one * minus_one

    return math.sqrt(1 - power_of_two)
end

local function in_out_circular(x: number)
    if x < 0.5 then
        local times_two = 2 * x
        local power_of_two = times_two * times_two

        return (1 - math.sqrt(1 - power_of_two)) * 0.5
    end

    local a = -2 * x + 2
    local power_of_two = a * a
    return (math.sqrt(1 - power_of_two) + 1) * 0.5
end

local function in_back(x: number)
	local c1 = 1.70158
	local c3 = c1 + 1
	return  c3 * x * x * x - c1 * x * x
end

local function out_back(x: number)
	local c1 = 1.70158
	local c3 = c1 + 1

    local a = x - 1
    local power_of_three = a * a * a
    local power_of_two = a * a

	return 1 + c3 * power_of_three + c1 * power_of_two
end

local function in_out_back(x: number)
	local c1 = 1.70158
	local c2 = c1 * 1.525

    if x < 0.5 then
        local times_two = x * 2
        local power_of_two = times_two * times_two
        local calc = ((c2 + 1) * 2 * x - c2)

        return (power_of_two * calc) * 0.5
    end
    
    local times_two = 2 * x - 2
    local power_of_two = times_two * times_two
    local calc = ((c2 + 1) * (x * 2 - 2) + c2)

    return ((power_of_two * calc) + 2) * 0.5
end

local function out_bounce(x: number)
	local n1 = 7.5625
	local d1 = 2.75

	if x < 1 / d1 then
		return n1 * x * x
	end

	if x < 2 / d1 then
		local a = (x - 1.5 / d1)
		local a_squared = a * a

		return n1 * a_squared + 0.75
	end

	if x < 2.5 / d1 then
		local a = (x - 2.5 / d1)
		local a_squared = a * a

		return n1 * a_squared + 0.9375
	end

	local a = (x - 2.625 / d1)
	local a_squared = a * a

	return n1 * a_squared + 0.984375
end

local function in_bounce(x: number)
	return 1 - out_bounce(1 - x)
end

local function in_out_bounce(x: number)
	if x < 0.5 then
		return (1 - out_bounce(1 - 2 * x)) * 0.5
	end
	
	return (1 + out_bounce(2 * x - 1)) * 0.5
end

local c4 = TAU / 3
local c5 = TAU / 4.5
local function in_elastic(x: number)
	if x == 0 then
		return 0
	end

	if x == 1 then
		return 1
	end

	return -math.pow(2, 10 * x - 10) * math.sin((x * 10 - 10.75) * c4)
end

local function out_elastic(x: number)
	if x == 0 then
		return 0
	end

	if x == 1 then
		return 1
	end

	return math.pow(2, -10 * x) * math.sin((x * 10 - 0.75) * c4) + 1
end

local function in_out_elastic(x: number)
	if x == 0 then
		return 0
	end

	if x == 1 then
		return 1
	end

	if x < 0.5 then
		return -(math.pow(2, 20 * x - 10) * math.sin((20 * x - 11.125) * c5)) * 0.5
	end

	return (math.pow(2, -20 * x + 10) * math.sin((20 * x - 11.125) * c5)) * 0.5 + 1
end


return table.freeze {
	Linear = table.freeze {
		In = linear,
		Out = linear,
		InOut = linear,
	},

	Smooth = table.freeze {
		In = smooth,
		Out = smooth,
		InOut = smooth,
	},
	
	Sine = table.freeze {
		In = in_sine,
		Out = out_sine,
		InOut = in_out_sine,
	},

	Quad = table.freeze {
		In = in_quad,
		Out = out_quad,
		InOut = in_out_quad,
	},
	
	Cubic = table.freeze {
		In = in_cubic,
		Out = out_cubic,
		InOut = in_out_cubic,
	},
	
	Bounce = table.freeze {
		In = in_bounce,
		Out = out_bounce,
		InOut = in_out_bounce,
	},

    Quart = table.freeze {
        In = in_quart,
        Out = out_quart,
        InOut = in_out_quart,
    },

    Quint = table.freeze {
        In = in_quint,
        Out = out_quint,
        InOut = in_out_quint,
    },
	
	Elastic = table.freeze {
		In = in_elastic,
		Out = out_elastic,
		InOut = in_out_elastic,
	},

    Back = table.freeze {
        In = in_back,
        Out = out_back,
        InOut = in_out_back,
    },

    Exponential = table.freeze {
		In = in_exponential,
		Out = out_exponential,
		InOut = in_out_exponential,
	},

    Circular = table.freeze {
        In = in_circular,
        Out = out_circular,
        InOut = in_out_circular,
    },
}
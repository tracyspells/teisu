local teisu = require("../../lib/init")
local types = require("../types")

type CASE = types.CASE
type CHECK = types.CHECK

local flec = teisu.flec
local show = teisu.show

return function(CASE: CASE, CHECK: CHECK)
    do
        CASE("shows component")

        local input = flec(true)
        local one = function() return 1 end

        local output = show(input, one)

        CHECK(output() == 1)
        input(false)
        CHECK(output() == nil)
    end

    do
        CASE("fallback component")

        local input = flec(true)
        local one = function() return 1 end
        local two = function() return 2 end

        local output = show(input, one, two)

        CHECK(output() == 1)
        input(false)
        CHECK(output() == 2)
    end
end

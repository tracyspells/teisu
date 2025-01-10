local teisu = require("../../lib/init")
local types = require("../types")

type CASE = types.CASE
type CHECK = types.CHECK

local root = teisu.root
local flec = teisu.flec
local effect = teisu.effect
local cleanup = teisu.cleanup

return function(CASE: CASE, CHECK: CHECK)
    do
        CASE("validate")
        local unroot = root(function()
            -- do nothing 
        end)

        CHECK(type(unroot) == "function")
        unroot()
    end

    do
        CASE("supports cleanup()")

        local updates = 0
        local cleaned_up = false

        local source = flec(0) 

        local unroot
        unroot = root(function() 
            local dispose = effect(function()
                source()
                updates += 1
            end)

            cleanup(function()
                dispose()
                cleaned_up = true
            end)
        end)

        CHECK(updates == 1)
        CHECK(cleaned_up == false)
        source(1)
        CHECK(updates == 2)
        CHECK(cleaned_up == false)
        unroot()
        CHECK(updates == 2)
        CHECK(cleaned_up == true)
    end
end

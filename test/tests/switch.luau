local teisu = require("../../lib/init")
local types = require("../types")

type CASE = types.CASE
type CHECK = types.CHECK

local flec = teisu.flec
local cleanup = teisu.cleanup
local switch = teisu.switch
local effect = teisu.effect
local root = teisu.root

return function(CASE: CASE, CHECK: CHECK)
    do
        CASE("update on source change")

        local input = flec(true :: boolean?)
        local output = switch(input) {
            [true] = function() return 1 end,
            [false] = function() return 0 end,
        }

        local count = 0
        local dispose = effect(function()
            output()
            count += 1
        end)

        CHECK(count == 1)
        CHECK(output() == 1)
        
        input(false)
        CHECK(output() == 0)
        CHECK(count == 2)

        input(false)
        CHECK(output() == 0)
        CHECK(count == 2)

        input(nil)
        CHECK(output() == nil)
        dispose()
    end

    do
        CASE("same component, different map")

        local input = flec(0)
        local function component() 
            return {} 
        end

        local output = switch(input) {
            [1] = component,
            [2] = component,
        }

        CHECK(output() == nil)

        input(1)
        local instance = output()
        CHECK(instance)

        input(2)
        CHECK(output() == instance)
    end

    do
        CASE("scoped switch")

        local switch0_count = 0
        local switch1_count = 0
        local owner_count = 0
        local changes = 0

        local input = flec(true)

        local unroot, output = root(function()  
            cleanup(function() owner_count += 1 end)

            return switch(input) {
                [true] = function()
                    cleanup(function() switch1_count += 1 end)
                    return 1
                end,
    
                [false] = function()
                    cleanup(function() switch0_count += 1 end)
                    return 0
                end
            }
        end)
    
        local dispose = effect(function()
            output()
            changes += 1
        end)

        changes = 0

        CHECK(output() == 1)
        input(false)
        CHECK(switch1_count == 1)
        CHECK(switch0_count == 0)
        CHECK(changes == 1)
        input(true)
        CHECK(switch1_count == 1)
        CHECK(switch0_count == 1)
        CHECK(changes == 2)
        input(nil :: never)
        CHECK(switch1_count == 2)
        CHECK(switch0_count == 1)
        CHECK(changes == 3)
        dispose()
        unroot()
        CHECK(owner_count == 1)
    end
end

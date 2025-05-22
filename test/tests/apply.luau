local teisu = require("../../lib/init")
local types = require("../types")

local apply = teisu.apply
local new = teisu.new
local show = teisu.show
local root = teisu.root
local flec = teisu.flec

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
    do
        CASE("apply properties to existing instance")

        local count = flec(0)
        local visible = flec(false)
        local destroy, frame = root(function()
            local instance = new "Frame" {
                BackgroundTransparency = 1,
            } :: Frame & { Count: number, hello: Frame? }

            apply(instance) { 
                Count = count,

                show(visible, function()
                    return new "Frame" {
                        BackgroundTransparency = 0,
                        Name = "hello",
                    }
                end)
            }
            
            return instance
        end)

        CHECK(frame.Count == 0)
        count(1)
        CHECK(frame.Count == 1)
        count(2)
        CHECK(frame.Count == 2)

        visible(true)
        CHECK(frame:FindFirstChild("hello") ~= nil)
        
        visible(false)
        CHECK(frame:FindFirstChild("hello") == nil)

        destroy()
        frame = nil :: never
    end
end

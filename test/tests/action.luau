local teisu = require("../../lib/init")
local types = require("../types")

local action = teisu.action
local new = teisu.new

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
    do
        CASE("run action")

        local ran = false
        
        local frame_ref
        local frame = new "Frame" {
            action(function(self)
                frame_ref, ran = self, true
            end)
        } :: Frame

        CHECK(ran)
        CHECK(frame_ref == frame)
    end
end

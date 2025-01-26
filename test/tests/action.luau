local teisu = require("../../lib/init")
local types = require("../types")

type CASE = types.CASE
type CHECK = types.CHECK

local action = teisu.action
local new = teisu.new

return function(CASE: CASE, CHECK: CHECK)
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

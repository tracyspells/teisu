local teisu = require("../../lib/init")
local teisu_graph = require("../../lib/graph")
local teisu_types = require("../../lib/types")
local types = require("../types")
local testkit = require("../testkit")

type CASE = types.CASE
type CHECK = types.CHECK

type Node<T> = teisu_types.Node<T>

local flec = teisu.flec
local show = teisu.show
local cleanup = teisu.cleanup
local castToNode = teisu_graph.castToReactable
local equals = testkit.seq

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

    do
		CASE("can be cleaned up")

        local one = function() return 1 end

		local source = flec(false)
        local source_node = castToNode(source)
		
        local output = show(source, one)
		local computed_node = castToNode(output)

        output()

        if computed_node then
            CHECK(not equals(computed_node.parents, {})) -- check if `output`'s parents arent empty
        end
        
		cleanup(output)
        source(true)
        
        CHECK(output() == nil)

        if source_node then
            CHECK(equals(source_node.children, {}))
        end

        if computed_node then
            CHECK(equals(computed_node.parents, {}))
        end

        source_node = nil
        computed_node = nil
	end
end

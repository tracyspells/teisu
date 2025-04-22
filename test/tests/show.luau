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
local root = teisu.root
local get_root_scope = teisu_graph.get_root_scope
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
        CASE("root() cleanup test")
        local one = function() return 1 end

		local input = flec(true)

        local root_scope
        local unroot, output = root(function()  
            root_scope = get_root_scope()

            return show(input, one)
        end)

        
        CHECK(root_scope and root_scope.n == 1)
        output() -- create a root scope internally
        unroot()
        CHECK(root_scope and root_scope.n == nil)
        root_scope = nil
    end

    do
		CASE("cleanup() test")

        local one = function() return 1 end

		local source = flec(true)
        local source_node = castToNode(source)
		
        local output = show(source, one)
		local computed_node = castToNode(output)

        output() -- create a root scope internally

        if computed_node then
            CHECK(not equals(computed_node.parents, {})) -- check if `output`'s parents arent empty
        end
        
		cleanup(output)
        source(false)
        
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

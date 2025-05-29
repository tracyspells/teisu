local teisu = require("../../lib/init")
local teisu_graph = require("../../lib/graph")
local teisu_types = require("../../lib/types")
local types = require("../types")
local testkit = require("../testkit")

type Node<T> = teisu_types.Node<T>

local flec = teisu.flec
local show = teisu.show
local cleanup = teisu.cleanup
local root = teisu.root
local castToNode = teisu_graph.castToReactable
local equals = testkit.seq

type SKIP = types.SKIP
type CASE = types.CASE
type CHECK = types.CHECK
type CHECK_EXPECT_ERROR = types.CHECK_EXPECT_ERROR

return function(SKIP: SKIP, CASE: CASE, CHECK: CHECK, CHECK_EXPECT_ERROR: CHECK_EXPECT_ERROR)
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
        local input = flec(true)
        local one = function() return 1 end

        local is_root_scope_cleaned_up = false
        local destroy, output = root(function()  
            cleanup(function() is_root_scope_cleaned_up = true end)

            return show(input, one)
        end)

        
        CHECK(is_root_scope_cleaned_up == false)

        output() -- create a root scope internally

        CHECK(output() == 1)
        input(false)
        CHECK(output() == nil)

        destroy() -- everything should be cleaned up at this point
        CHECK(is_root_scope_cleaned_up == true)
        CHECK(output() == nil)
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

        CHECK(output() == 1)

        if source_node then
            CHECK(equals(source_node.children, {}))
        end

        if computed_node then
            CHECK(equals(computed_node.parents, {}))
        end

        source_node = nil
        computed_node = nil
	end

    do
        CASE("scoped show")

        local component_cleanup_count = 0
        local fallback_cleanup_count = 0
        local is_root_scope_cleaned_up = false

        local input = flec(true :: boolean?)

        local destroy, output = root(function()
            local output  
            cleanup(function() is_root_scope_cleaned_up = true end)

            output = show(
                input, 
                function()
                    cleanup(function() component_cleanup_count += 1 end)

                    return 1  
                end,

                function()
                    cleanup(function() fallback_cleanup_count += 1 end)

                    return 2  
                end
            )

            return output
        end)

        CHECK(is_root_scope_cleaned_up == false)

        CHECK(output() == 1)

        input(false)

        CHECK(output() == 2)
        CHECK(component_cleanup_count == 1)
        CHECK(fallback_cleanup_count == 0)

        input(true)

        CHECK(output() == 1)
        CHECK(component_cleanup_count == 1)
        CHECK(fallback_cleanup_count == 1)

        input(false)

        CHECK(output() == 2)
        CHECK(component_cleanup_count == 2)
        CHECK(fallback_cleanup_count == 1)

        input(nil)
        CHECK(output() == 2)
        CHECK(component_cleanup_count == 2)
        CHECK(fallback_cleanup_count == 2)

        destroy()
        CHECK(is_root_scope_cleaned_up == true)
    end

    do
        CASE("dont show component if input isnt truthy")

        local input = flec(false)
        local one = function() return 1 end

        local output = show(input, one)
        CHECK(output() ~= 1)

        input(true)
        CHECK(output() == 1)

        input(false)
        CHECK(output() ~= 1)
    end

    do
        CASE("supports constants")

        local input = "Hello, world!"
        local output = show(input, function()
            return input  
        end)

        CHECK(output() == input)
        cleanup(output)
        CHECK(output() == input)
    end
end

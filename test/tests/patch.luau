local patch = require("../../lib/sync/patch")
local teisu_types = require("../../lib/types")
local types = require("../types")
local testkit = require("../testkit")

type CASE = types.CASE
type CHECK = types.CHECK

type Patch<K, V> = teisu_types.Patch<K, V>
type PatchOperation = teisu_types.PatchOperation
type NONE = teisu_types.NONE

local diff, apply = patch.diff, patch.apply
local equals = testkit.deq

local NONE = { __none = "__none" } :: NONE

return function(CASE: CASE, CHECK: CHECK)
    do
        CASE("array patches")

        local a = { 1, 2, 3 }
        local b = { 4, 5, 6 }
        local desired_patches = {
            {
                op = "replace",
                path = { 1 },
                value = 4,
            },

            {
                op = "replace",
                path = { 2 },
                value = 5,
            },

            {
                op = "replace",
                path = { 3 },
                value = 6,
            }
        } :: { Patch<number, number> }

        local patches = diff(a, b) :: { Patch<number, number> }
        CHECK(equals(patches, desired_patches))
    end

    do
        CASE("dictionary patches")

        local a = { foo = "bar" }
        local b = { bar = "foo", a = 2 }
        local desired_patches = {
            {
                op = "remove",
                path = { "foo" },
                value = NONE 
            },

            {
                op = "add",
                path = { "a" },
                value = 2,
            },

            {
                op = "add",
                path = { "bar" },
                value = "foo",
            },
        } :: { Patch<string, number | string | NONE> }

        local patches = diff(a, b) :: { Patch<string, number | string | NONE> }
        CHECK(equals(patches, desired_patches))
    end

    do
        CASE("nested patches")

        local a = { foo = { bar = 2 }}
        local b = { foo = { bar = 3 }, a = 2 }
        local desired_patches = {
            {
                op = "replace",
                path = { "foo", "bar" },
                value = 3
            },

            {
                op = "add",
                path = { "a" },
                value = 2,
            },
        } :: { Patch<string, number | string | NONE> }

        local patches = diff(a, b) :: { Patch<string, number | string | NONE> }
        CHECK(equals(patches, desired_patches))
    end

    do
        CASE("applies patches")

        local prevState = { foo = "bar", baz = "qux" }
		local patches = { 
            {
                op = "replace",
                path = { "baz" },
                value = "quux",
            },

            {
                op = "add",
                path = { "qaz" },
                value = "qux"
            }
        } :: { Patch<string, string> }
        
        
        local applied = apply(prevState, patches)
        CHECK(applied ~= nil)
        CHECK(applied.baz == "quux")
        CHECK(applied.qaz == "qux")
        CHECK(applied.foo == "bar")
    end

    do
        CASE("preserves sparse arrays")

        local prevState = {}
		local nextState = { [2] = "foo" }

        local patches = diff(prevState, nextState)
        local applied 

        if patches then
            applied = apply(prevState, patches)
        end

        CHECK(equals(applied, nextState))
    end
end

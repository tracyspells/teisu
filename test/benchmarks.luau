local teisu = require("../lib")
local testkit = require("@testkit/")

local flec = teisu.flec
local computed = teisu.computed
local batch = teisu.batch

local N = 2 ^ 18 -- 262144

local BENCH, START = testkit.benchmark()

local function TITLE(name: string)
	print(`\n` .. testkit.color.white_underline(name) .. `\n`)
end


TITLE "flecs"

BENCH("flec creation", function()  
    local cache = table.create(N)

    for i = 1, N do
        cache[i] = flec(1)
    end
end)

BENCH("get value", function()
    local source = flec(0)
    
    for _ = 1, START(N) do
        source()
    end
end)

BENCH("set value", function()
    local source = flec(0)
    
    for i = 1, START(N) do
        source(i)
    end
end)

BENCH("computed derived from 1 flec", function()
    local cache = table.create(N)
    local src = flec(1)

    for i = 1, START(N) do
        cache[i] = computed(function()
            return src()
        end)()
    end
end)

BENCH("computed derived from 4 flecs", function()
    local cache = table.create(N)
    local a = flec(1)
    local b = flec(2)
    local c = flec(3)
    local d = flec(4)

    for i = 1, START(N) do
        cache[i] = computed(function()
            return a() + b() + c() + d()
        end)()
    end
end)

TITLE "graphs"

BENCH("a --> b", function() 
    local a = flec(0)
    computed(function() return a() end)()

    for i = 1, START(N) do
        a(i)
    end
end)

BENCH("1 --> 1000", function()
    local src = flec(-1)

    for i = 1, 1000 do
        computed(function() return src() end)()
    end

    src(0)

    for i = 1, START(10) do
        src(i)
    end
end)

BENCH("update 1->1->1->1...1000 graph", function()
    local src = flec(-1)

    local last = src
    for i = 1, 1000 do
        local l = last
        last = computed(function() return l() end)
        last()
    end

    src(0)

    for i = 1, START(10) do
        src(i)
    end
end)

BENCH("update 1000->1 graph", function()
    local srcs = {}
    for i = 1, 1000 do
        srcs[i] = flec(0)
    end

    computed(function()
        for i = 1, 1000 do
            srcs[i]()
        end
        return false
    end)()

    for idx = 1, START(1000) do
        srcs[idx](idx)
    end
end)

BENCH("update 1000->1 graph (batched)", function()
    local srcs = {}
    for i = 1, 1000 do
        srcs[i] = flec(0)
    end

    computed(function()
        for i = 1, 1000 do
            srcs[i]()
        end
        return false
    end)()

    for i = 1, START(1) do
        batch(function()
            for idx = 1, 1000 do
                srcs[idx](i)
            end
        end)
    end
end)

return nil
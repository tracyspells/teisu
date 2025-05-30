--[[

https://github.com/centau/vide/blob/main/test/mock.luau

]]

local Signal = {} :: any do
    Signal.__index = Signal
    Signal.__type = "RBXScriptSignal"

    local function new_connection(signal, fn)
        return {
            signal = signal,
            fn = fn,

            Disconnect = function(self)
                local i = table.find(signal.connections, self)
                if not i then return end
                table.remove(signal.connections, i)
            end
        }
    end

    function Signal.new()
        return setmetatable({
            connections = {}
        }, Signal)
    end

    function Signal.Connect(self, fn)
        local con = new_connection(self, fn)
        table.insert(self.connections, con)
        return con
    end

    function Signal.Once(self, fn)
        local connection 
        connection = self:Connect(function()
            connection:Disconnect()
            fn()
        end)

        return connection
    end

    function Signal.fire(self, ...)
        for i = #self.connections,  1, -1 do
            self.connections[i].fn(...)
        end
    end
end

local Instance = {} :: any do
    --[[

    attempt to mimic roblox engine's method of userdata reflection
    proxy can gc independantly of actual instance data
    proxy prevents gc of actual instance data
    user code never has direct access to actual instance data, only to proxy
    internal weak map kept data -> proxy
    
    ]]

    type userdata = { __USERDATA: true }

    type ProxyMT = {
        proxy: userdata,
        data: Data,
        __index: any,
        __newindex: any
    }

    type Data = {
        name: string,
        parent: Data?,
        children: { Data },
        changed: { [string]: RBXScriptSignal },
        properties: { [string]: unknown },
        destroying: RBXScriptSignal,
        class: string,
        type: "Instance"
    }

    local function deep_clone<T>(template: T & {}): T
        local t = table.clone(template :: {}) :: {}

        for i, v in next, t do
            if type(v) == "table" then
                t[i] = deep_clone(v)
            end
        end

        return t :: T & {}
    end

    local proxies = {} :: { [Data]: userdata? }
    setmetatable(proxies :: any, { __mode = "v" })

    local function get_data(userdata: userdata): Data
        local function f(userdata: userdata): ProxyMT
            return getmetatable(userdata :: any)
        end

        return f(userdata).data
    end

    local function is_instance(value: unknown): boolean
        local mt = getmetatable(value :: any)
        return mt and mt.data and mt.data.type == "Instance"
    end

    local methods = {}

    local function __index(userdata: userdata, property: string): ()
        local data = get_data(userdata)
        return if methods[property] then methods[property]
            elseif property == "Name" then data.name
            elseif property == "Parent" then data.parent
            elseif property == "Destroying" then data.destroying
            else data.properties[property] 
    end

    local function __newindex(userdata: userdata, property: string, value: unknown)
        local data = get_data(userdata)
        if property == "Name" then
            if type(value) ~= "string" then error("name must be a string", 2) end
            data.name = value :: string
        elseif property == "Parent" then
            assert(value == nil or is_instance(value), "attempt to set non-instance as parent")
            local parent = data.parent
            if parent then
                data.parent = nil
                table.remove(parent.children, table.find(parent.children, data))
            end
            if value then
                data.parent = get_data(value :: userdata)
                table.insert(get_data(value :: userdata).children, data)
            end
        else
            data.properties[property] = value
        end

        if data.changed[property] then
            Signal.fire(data.changed[property])
        end
    end

    local function get_proxy(data: Data): userdata
        return proxies[data] or (function()
            local userdata = newproxy(true)
            local proxy = getmetatable(userdata)
            proxy.proxy = userdata
            proxy.data = data
            proxy.__index = __index
            proxy.__newindex = __newindex
            proxies[data] = userdata   
            return userdata
        end)()
    end

    function Instance.new(class: string): Instance
        local data = {
            name = "UNNAMED",
            parent = nil,
            children = {},
            changed = {},
            properties = {},
            class = class,
            destroying = Signal.new() :: any,
            type = "Instance" :: "Instance"
        }

        return get_proxy(data) :: any
    end

    function Instance.is_instance(value: unknown): boolean
        return is_instance(value)
    end

    function methods.Clone(userdata: userdata): userdata
        local data = get_data(userdata)
        local clone_userdata = (Instance.new("") :: any) :: userdata
        local clone_data = get_data(clone_userdata)

        for i, v in next, deep_clone(data) do
            clone_data[i] = v
        end

        return clone_userdata
    end

    function methods.FindFirstChild(userdata: userdata, target: string): userdata?
        local data = get_data(userdata)
        for _, child in data.children do
            if child.name == target then
                return get_proxy(child)
            end
        end
        return nil
    end

    function methods.GetChildren(userdata: userdata): { userdata }
        local children = get_data(userdata).children
        local userdatas = table.create(#children)

        for i, child in next, children do
            userdatas[i] = get_proxy(child)
        end

        return userdatas
    end

    function methods.GetPropertyChangedSignal(userdata: userdata, property: string): RBXScriptSignal
        local data = get_data(userdata)
        if not data.changed[property] then
            data.changed[property] = Signal.new() :: any
        end
        return data.changed[property]
    end

    function methods.Destroy(userdata: userdata)
        local data = get_data(userdata);
        Signal.fire(data.destroying)
        data.parent = nil
        if data.changed["Parent"] then
            Signal.fire(data.changed["Parent"])
        end
    end
end

local function table_to_proxy(t: any)
    local proxy = newproxy(true)
    local mt = getmetatable(proxy)

    for i, v in getmetatable(t) do
        mt[i] = v
    end

    function mt:__index(i)
        return t[i]
    end

    function mt:__newindex(i, v)
        t[i] = v
    end

    return proxy
end

local Color3 = { __type = "Color3" } :: any do
    function Color3.new(r, g, b)
        return table_to_proxy(setmetatable({ R = r, G = g, B = b }, Color3))
    end

    function Color3.fromRGB(r, g, b)
        return Color3.new(r, g, b)
    end

    function Color3.lerp(self, to, alpha)
        local r = self.R + (to.R - self.R) * alpha
        local g = self.G + (to.G - self.G) * alpha
        local b = self.B + (to.B - self.B) * alpha

        return Color3.fromRGB(r, g, b)
    end

    function Color3.__eq(a, b)
        return a.R == b.R and a.G == b.G and a.B == b.B
    end
end

local Vector2 = { __type = "Vector2" } :: any do
    function Vector2.new(x, y)
        return table_to_proxy(setmetatable({ X = x, Y = y }, Vector2))
    end

    function Vector2.__eq(a, b)
        return a.X == b.X and a.Y == b.Y
    end

    Vector2.zero = Vector2.new(0, 0)
    Vector2.one = Vector2.new(1, 1)
    Vector2.xAxis = Vector2.new(1, 0)
    Vector2.yAxis = Vector2.new(0, 1)
end

local Vector3 = { __type = "Vector3" } :: any do
    function Vector3.new(x, y, z)
        return table_to_proxy(setmetatable({ X = x, Y = y, Z = z }, Vector3))
    end

    function Vector3.__eq(a, b)
        return a.X == b.X and a.Y == b.Y and a.Z == b.Z
    end

    Vector3.zero = Vector3.new(0, 0, 0)
    Vector3.one = Vector3.new(1, 1, 1)
    Vector3.xAxis = Vector3.new(1, 0, 0)
    Vector3.yAxis = Vector3.new(0, 1, 0)
    Vector3.zAxis = Vector3.new(0, 0, 1)
end

local UDim2 = { __type = "UDim2" } :: any do
    function UDim2.new(sx, ox, sy, oy)
        return table_to_proxy(setmetatable({ X = { Scale = sx, Offset = ox }, Y = { Scale = sy, Offset = oy } }, UDim2))
    end

    function UDim2.fromScale(x, y)
        return table_to_proxy(setmetatable({ X = { Scale = x, Offset = 0 }, Y = { Scale = y, Offset = 0 } }, UDim2))
    end

    function UDim2.fromOffset(x, y)
        return table_to_proxy(setmetatable({ X = { Scale = 0, Offset = x }, Y = { Scale = 0, Offset = y } }, UDim2))
    end

    function UDim2.__eq(a, b)
        return a.X.scale == b.X.scale and
            b.X.offset == b.X.offset and
            a.Y.scale == b.Y.scale and
            a.Y.offset == b.Y.offset
    end
end

local Enum = {} :: any do
    setmetatable(Enum, { __index = function(self, index)
        local v = setmetatable({}, { __index = function(self, index) 
            self[index] = true
            return true
        end})
        self[index] = v
        return v
    end})
end

local typeof = function(v)
    return if Instance.is_instance(v) then "Instance"
        elseif getmetatable(v) and getmetatable(v).__type then getmetatable(v).__type
        else type(v)
end :: any

local t = {} :: any do
    local function spawn<A..., R...>(fn: thread | (A...) -> R..., ...: A...): thread
        if type(fn) == "thread" then
            coroutine.resume(fn, ...)
            return fn
        end

        local thread = coroutine.create(fn)
        coroutine.resume(thread, ...)
        return thread
    end

    local function wait(seconds: number?): number
        local start_time = os.clock()
        local end_time = start_time + (seconds or 1)
        local clock_time: number

        repeat
            clock_time = os.clock()
        until clock_time >= end_time 

        return clock_time - start_time
    end

    local function close(thread: thread)
        local ok = coroutine.close(thread)

        if not ok then
            error(debug.traceback(thread, "[TASK]: could not cancel thread"))
        end
    end

    local function delay<A..., R...>(
        seconds: number, 
        fn: thread | (A...) -> R..., 
        ...: A...
    )
        return spawn(function(
            seconds: number, 
            fn: thread | (A...) -> R..., 
            ...: A...
        )
            wait(seconds)
            if type(fn) == "thread" then
                coroutine.resume(fn, ...)
            else
                fn(...)
            end
        end, seconds, fn, ...)
    end

    t.spawn = spawn
    t.wait = wait
    t.cancel = close
    t.delay = delay
    t = table.freeze(t)
end

return table.freeze {
    Signal = Signal,
    Instance = Instance :: typeof(Instance),
    Color3 = Color3 :: typeof(Color3),
    Vector2 = Vector2 :: typeof(Vector2),
    Vector3 = Vector3 :: typeof(Vector3),
    UDim2 = UDim2 :: typeof(UDim2),
    Enum = Enum :: typeof(Enum),
    typeof = typeof :: typeof(typeof),
    task = t :: typeof(task)
}
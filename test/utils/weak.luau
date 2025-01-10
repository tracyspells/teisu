return function<T>(t: T & {}): T
    setmetatable(t :: {}, { __mode = "kv" })
    return t
end

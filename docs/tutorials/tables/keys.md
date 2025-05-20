# Keys

`Teisu.keys` is a state object that processes keys from another table.

## Usage

To create a `keys` object, call `Teisu.keys` and pass in an input molecule and a transformer function.

```luau
local keys = Teisu.keys

local data = flec({ foo = "bar", bar = "bazz" })

local uppercase = keys(data, function(key)
    return string.upper(key)
end)
```

You can access `uppercase`'s contents like a `computed`:

```luau
print(uppercase()) --> { FOO = "bar", BAR = "bazz" }
print(peek(uppercase))
```

Whenever your input molecule changes, the output will update.

```luau
data(function(old)
    local new = table.clone(old)
    new.foo = nil

    return new
end)

print(uppercase()) --> { BAR = "bazz" }
```
If `Teisu.cleanup` is called, any object passed in as an argument will get cleaned up when a processed key is removed.

::: code-group

```luau [Luau code] {2-4}
local uppercase = keys(data, function(key)
    cleanup(function()
        print("removed a key!")
    end)

    return string.upper(key)
end)

data(function(old)
    local new = table.clone(old)
    new.foo = nil

    return new
end)
print(uppercase())
```

```luau [Output]
removed a key!
{ BAR = "bazz" }
```
:::

# Indexes

`Teisu.indexes` is a state object that processes indexes instead of values.

## Usage

To create an `indexes` object, call `Teisu.indexes` and pass in an input molecule and a transformer function.

```luau
local indexes = Teisu.indexes

local todos = flec({ "go shopping", "eat food", "head back home" })

local numbered_todos = indexes(todos, function(value, index)
    return `{index()}. {value}`
end)
```

You can access `numbered_todos`'s contents like a `computed`:

```luau
print(numbered_todos()) --> { "1. go shopping", "2. eat food", "3. head back home" }
print(peek(numbered_todos))
```

Whenever your input molecule changes, the output will update.

```luau
todos({ "eat food", "go shopping", "head back home" })

print(numbered_todos()) --> { "1. eat food", "2. go shopping", "3. head back home" }
```

If `Teisu.cleanup` is called, any object passed in as an argument will get cleaned up when a processed key is removed.

::: code-group

```luau [Luau code] {2-4}
local numbered_todos = indexes(todos, function(value)
    cleanup(function()
        print("removed a todo!")
    end)

    return `{index()}. {value}`
end)

todos({ "eat food", "head back home" })

print(numbered_todos())
```

```luau [Output]
removed a todo!
{ "1. eat food", "2. head back home" }
```
:::
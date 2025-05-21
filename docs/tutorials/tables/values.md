# Values

At some point you may need to transform values in your state into new ones. You can accomplish this with `Teisu.values`.

## Usage

To create a `values` object, call `Teisu.values` and pass in an input molecule and a transformer function.

```luau
local values = Teisu.values

local todos = flec({ "go shopping", "eat food", "head back home" })

local uppercase = values(todos, function(value)
    return string.upper(value())
end)
```

You can access `uppercase`'s contents like a `computed`:

```luau
print(uppercase()) --> { "GO SHOPPING", "EAT FOOD", "HEAD BACK HOME" }
print(peek(uppercase))
```

Whenever your input molecule changes, the output will update.

```luau
todos(function(old_list)
    local new_list = table.clone(old_list)
    table.remove(new_list, 1)

    return new_list
end)

print(uppercase()) --> { "EAT FOOD", "HEAD BACK HOME" }
```

If `Teisu.cleanup` is called, any object passed in as an argument will get cleaned up when a processed key is removed.

::: code-group

```luau [Luau code] {2-4}
local uppercase = values(todos, function(value)
    cleanup(function()
        print("removed a todo!")
    end)

    return string.upper(value())
end)

todos(function(old_list)
    local new_list = table.clone(old_list)
    table.remove(new_list, 1)

    return new_list
end)

print(uppercase())
```

```luau [Output]
removed a todo!
{ "EAT FOOD", "HEAD BACK HOME" }
```
:::

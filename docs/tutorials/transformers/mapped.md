# Mapped

At some point you may need to transform keys and values in your state into new ones. You can accomplish this with `Teisu.mapped`.

## Usage

To create a mapped object, call `Teisu.mapped` and pass in an input molecule and a transformer function.

```luau
local mapped = Teisu.mapped

local todos = flec({ "go shopping", "eat food", "head back home"})

local uppercase = mapped(todos, function(value)
    return string.upper(value())
end)
```

You can access `uppercase`'s contents like a `computed`:

```luau
print(uppercase()) --> { "GO SHOPPING", "EAT FOOD", "HEAD BACK HOME"}
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
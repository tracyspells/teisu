# Contexts

## Creating a context

To create a context, import `Teisu.context` into your code and simply call it.

::: code-group 

```luau [myContext.luau]
local context = Teisu.context

local myContext = context()

return myContext
```
:::

## Providing context to children

To pass a value to components that need said value, we can use the `.provide` method. The value that you pass in can be anything, including molecules.

::: code-group 

```luau {5-7} [myContext.luau]
local context = Teisu.context

local myContext = context()

local function myProvider(props: { children: () -> any })
    return myContext.provide("Hello, world!", props.children)
end

return {
    provider = myProvider,
    context = myContext
}
```
:::

## Consuming the context

To access the value that was passed to `myProvider`, we need to call `.consume`.

::: code-group
```luau {4} [component.luau]
local myContext = require("path/to/myContext.luau").context

return function()
    local value = myContext.consume()

    return text_component {
        Text = `{value}`
        TextSize = 32,
    }
end
```

```luau {7} [app.client.luau]
local myProvider = require("path/to/myContext.luau").provider
local component = require("path/to/component.luau")

local mount = Teisu.mount

mount(function()
    return myProvider({ children = component })
end, Players.LocalPlayer.PlayerGui)
```
:::


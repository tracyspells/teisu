# Context

Sometimes it can be inconvenient to pass props down manually at every layer of functions. `Teisu.context` is designed to share global information that's regularly accessed by multiple components without passing it explicitly through props.

## When should I use context?

Context can be used when you got multiple components across your application that need shared state. `Teisu.context` can be employed to avoid prop drilling (the practice of passing props to children components through intermediate components that don't necessarily need the props).

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

We're going to create a helper function called `myProvider` that makes providing context to components a bit easier.

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

## Customizing context utilities

It is often a good idea to wrap `.consume` in a custom utility function to access the context values.

We'll rewrite `myContext.luau` and `component.luau` like so:

::: code-group 

```luau {9-13} [myContext.luau]
local context = Teisu.context

local myContext = context()

local function myProvider(props: { children: () -> any })
    return myContext.provide("Hello, world!", props.children)
end

local function useMyContext()
    local value = myContext.consume()

    return value
end

return {
    provider = myProvider,
    
    useMyContext = useMyContext
}
```

```luau {3,6} [component.luau]
local myContext = require("path/to/myContext.luau")

local useMyContext = myContext.useMyContext

return function()
    local value = useMyContext()

    return text_component {
        Text = `{value}`
        TextSize = 32,
    }
end
```
:::


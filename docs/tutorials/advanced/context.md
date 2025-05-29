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

::: code-group 
```luau [myContext.luau]
local counter = flec(0)

local function callback()
    print("hi!")

    return true
end

myContext.provide("Hello, world!", callback)
myContext.provide(counter, callback)

```
:::

The `callback` function will run **immediately** as soon as you pass it to `.provide`. This callback function is mainly used to parent components so that they can grab the value stored in `myContext`.

It's best to create a wrapper around `.provide`.

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

    return some_text_component {
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
```luau {9-13,18} [myContext.luau]
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

    return some_text_component {
        Text = `{value}`
        TextSize = 32,
    }
end
```
:::

## Combining multiple context providers

In situations where you may need to use multiple context providers, you may approach the situation like so:

::: code-group
```luau [app.client.luau]
local themeContext = require("path/to/themeContext.luau")
local coinsContext = require("path/to/coinsContext.luau")

local themeProvider = themeContext.provider
local coinsProvider = coinsContext.provider

mount(function()
    return themeProvider({
        children = function()
            return coinsProvider({
                children = function()
                    -- eventually, your code
                end
            })
        end
    })
end, Players.LocalPlayer.PlayerGui)
```
:::

However, the code at the end will be pretty hard to read. Here is a utility function you can use to help with this:

```luau
type ProviderProps = { children: () -> any }
type Provider = (props: ProviderProps) -> any

function recurseProviders(providers: { Provider }, index: number, children: () -> any)
	if index > #providers then return children() end

	return providers[index] {
		children = function()
			return recurseProviders(providers, index + 1, children)
		end,
	}
end

local function ProviderStack(props: {
	providers: { Provider },
	children: () -> any,
})
	return recurseProviders(props.providers, 1, props.children)
end
```

Now we can rewrite our `app.client.luau` with our new utility function:

::: code-group
```luau [app.client.luau]
local themeContext = require("path/to/themeContext.luau")
local coinsContext = require("path/to/coinsContext.luau")
local ProviderStack = require("path/to/ProviderStack.luau")
local component = require("path/to/component.luau")

local themeProvider = themeContext.provider
local coinsProvider = coinsContext.provider

mount(function()
    return ProviderStack {
        providers = {
            themeProvider,
            coinsProvider,
        },

        children = component
    }
end, Players.LocalPlayer.PlayerGui)
```

```luau [component.luau]
local themeContext = require("path/to/themeContext.luau")
local coinsContext = require("path/to/coinsContext.luau")

local useCoins = coinsContext.useCoins
local useTheme = themeContext.useTheme

return function()
    local theme = useTheme()
    local coins_molecule = useCoins()

    return some_text_component {
        TextColor = computed(function()
            local currentTheme = theme()

            if currentTheme == "black" then
                return Color3.fromRGB(0, 0, 0)
            elseif currentTheme == "white" then
                return Color3.fromRGB(255, 255, 255)
            end

            return Color3.fromRGB(255, 0, 0)
        end)

        Text = computed(function()
            local coins = coins_molecule()

            return `Coins: {coins}`
        end)
        TextSize = 32,
    }
end
```
:::

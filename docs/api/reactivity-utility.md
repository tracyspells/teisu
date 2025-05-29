# Reactivity: Utility

## cleanup()

If called outside a scope, it will run the callback **immediately**. If called inside a scope, it queues the callback to run when the scope is destroyed.

```luau
function cleanup(object: Function | Disconnectable | Destroyable | Animatable<unknown> | thread)

type Animatable<T> = Spring<T> | Tween<T>
type Function = () -> ()
type Disconnectable = { Disconnect: Function } | { disconnect: Function }
type Destroyable = { Destroy: Function } | { destroy: Function }
```

### Parameters

-   `object`: An object that can be destroyed.

### Returns

`cleanup()` does not return anything.

**Example:**

```luau

-- runs immediately 
cleanup(function()
    print('hi')
end)

local source = flec(0)

local unroot = root(function()
    cleanup(function()
        print('cleaned')
    end)

    effect(function()
        print(`{source()}`)
    end)
end)

source(1)
source(2)
unroot() -- prints 'cleaned' and destroys the effect 
```

## peek()

A utility function that calls a function without tracking it as a dependency of an effect or a computed object.

```luau
function peek<T>(value: T | () -> T, dont_untrack: boolean?): T
```

### Parameters

-   `value`: Any value. If the value is a function, `peek` will call it without tracking any dependencies and returns the result.

-  **optional** `dont_untrack`: If this is set to true and `value` is a function, `peek` will call the function, allowing dependencies to be tracked and returns the result. Defaults to `false`.

### Returns

`peek` returns the result of the given function. If `value` is not a function, it will return the value as-is.

**Example:**

```luau
local nameFlec = flec("Alice")
local ageFlec = flec(21)
local dislikesFlec = flec({ "hockey", "fish", "tarantulas" })

effect(function()
	local name = nameFlec()
	local age = peek(ageFlec)
    local dislikes = peek(dislikesFlec, true) -- allows the `dislikesFlec` to be tracked as a dependency
end)
```


## batch()

Defers state changes until after the callback has ran. This is useful when you need to make multiple changes to the state and only want effects and computeds to be notified once.

```luau
function batch(callback: () -> ()): ()
```

### Parameters

-   `callback`: A function that updates flecs. Effects and computeds will only be notified once all changes have been applied.

### Returns

`batch` does not return anything.


**Example:**

```luau
local a = flec(0)
local b = flec(0)

effect(function()
    print(a() + b())
end)

-- prints "0"

batch(function()
    a(1) -- no print
    b(2) -- no print
end)

-- prints "3"
```

## context()

Provides a way to pass data through the component tree without needing to pass props through components manually (also known as [prop drilling](https://kentcdodds.com/blog/prop-drilling)).

```luau
export type Context<T> = {
	provide: <V>(value: T, callback: (() -> V)) -> V,
	consume: () -> T,
}

function context<T>(): Context<T>
function context<T>(default_value: T): Context<T>
```

### Parameters

- **optional** `default_value`: If this is not specified, `default_value` is set to `nil`. The default value *cannot* be changed.

### Returns

`Teisu.context` returns a object with the following methods:
   
   - `.provide`: Provides a value that components can consume via `.consume`, along with a callback that will run immediately. This will create a new context with the given value.
   - `.consume`: Grabs the context value that was provided via `.provide`. If no value is found, the function will return `default_value`.

::: danger
You cannot use these methods outside of a scope.
:::

**Example:**

::: code-group

```luau [themeContext.luau]
local context = Teisu.context
local flec = Teisu.flec

type Molecule<T> = Teisu.Molecule<T>
type Context<T> = Teisu.Context<T>

type Theme = ("black" | "white")
type ProviderProps = { children: () -> any }

local themeContext: Context<Theme> = context()

local function themeProvider(props: ProviderProps)
    local theme = flec("black" :: Theme)

    return counterContext.provide(theme, props.children)
end

local function useTheme(): Molecule<Theme>
    local theme = themeContext.consume()

    if theme == nil then
        -- Teisu will not error if the value returned by `.consume` is `nil`.
        -- Detecting this is up to the user.
        error(`cannot find theme`)
    end

    return theme
end

return {
    provider = themeProvider,

    useTheme = useTheme,
}
```

```luau [app.luau]
local themeContext = require("path/to/themeContext.luau")

local computed = Teisu.computed
local mount = Teisu.mount
local themeProvider, useTheme = themeContext.provider themeContext.useTheme

local function component()
    local theme = useTheme()
    local text_color = computed(function()
        if theme() == "black" then
            return Color3.fromRGB(0, 0, 0)
        end

        return Color3.fromRGB(255, 255, 255)
    end)

    return some_text_component {
        Text = "Hello, world!"
        TextColor = text_color,
        TextSize = 32,
    }
end

mount(function()
    return themeProvider({ children = component })
end, Players.LocalPlayer.PlayerGui)

```
:::

# Context

Provides a way to pass data through the component tree without needing to pass data as props through components manually (also known as prop drilling).

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

`Teisu.context` returns a context object with the following methods:
   
   - `.provide`: Provides a value that components can consume via `.consume`, along with a callback that will run immediately with the new value.
   - `.consume`: Grabs the value that was provided via `.provide`. If no value is found, the function will return `default_value`.

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

local new = Teisu.new
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

    return new "TextLabel" {
        BackgroundTransparency = 1,
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
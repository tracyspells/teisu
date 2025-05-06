# Effects

When working with flecs, it can be useful to track changes that happen to them. Effects allow you to do so.

Effects are special functions that are ran in response to `flec` updates. Think of a `flec` as a signal, and an `effect` as a connection.

## Usage

To create an `effect`, call `Teisu.effect`:

```luau{3,8,9,10}
local Teisu = require(game.ReplicatedStorage.Teisu)

local effect = Teisu.effect
local flec = Teisu.flec

local count = flec(0)

effect(function()
    print(`count: {count()}`)
end)
```

Effects are ran once to collect flecs that are ready to be read...

::: code-group

```luau [Luau code]
local count = flec(0)

effect(function()
    print(`count: {count()}`)
end)
```

```luau [Output]
count: 0
```

:::

...and then again whenever any flec changes.

::: code-group

```luau [Luau code]
effect(function()
    print(`count: {count()}`)
end)

count(1)
count(2)
```

```luau [Output]
count: 0
count: 1 -- [!code ++]
count: 2 -- [!code ++]
```

:::

If you don't want a flec to be tracked as a dependency, `peek` is your best friend!

::: code-group

```luau [Luau code]
local flec = Teisu.flec
local peek = Teisu.peek
local effect = Teisu.effect

local a = flec(0)
local b = flec(0)

effect(function()
    print(`a: {a()}, b: {peek(b)}`) -- [!code highlight]
end)

a(1)
b(1) -- [!code highlight]
a(2)
```

```luau [Output]
a: 0, b: 0
a: 1, b: 0
(prints nothing) -- [!code highlight]
a: 2, b: 1
```
:::

### Disposing effects

An `effect` returns a function that destroys itself. When this function is called, any subsequent changes will not rerun the callback.

```luau
local count = flec(0)

local dispose = effect(function()
    print(`count: {count()}`)
end)

-- destroys the effect after 5 seconds
task.wait(5)
dispose()

count(2) --> will not print anything
```

In situations where you need to disconnect the effect from the inside, use the `dispose` function.

```luau
local count = flec(0)

effect(function(dispose)
    if count() == 1 then
        dispose()
    end
end)
```

Effects, when used effectively and efficiently, can make state management feel awesome. In the next section, you'll discover Teisu's built in methods to simplify change tracking.
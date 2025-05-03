# Flecs

Flecs are the core of Teisu's reactivity. They are functions that hold a single value. Calling them can write to, or read from that value.

## Usage

To create a new flec, call `Teisu.flec` and give it a value you want it to store.

```luau
local Teisu = require(game.ReplicatedStorage.Teisu)

local flec = Teisu.flec

local health = flec(100) -- [!code highlight]
```

### Reading a flec

To get the value stored in `health`, call the function with no arguments passed in.

```luau
print(health()) --> 100
```

Teisu provides `peek()`, a function that allows you to read the value of whatever you give it. `peek()` is useful in most situations, but for now, this is an alternative to reading flecs.

```luau
local Teisu = require(game.ReplicatedStorage.Teisu)

local flec = Teisu.flec
local peek = Teisu.peek

local health = flec(100)
print(peek(health)) --> 100
```

### Writing to a flec

To modify the value stored in `health`, call the flec and pass in a new value as your argument.

```luau
local flec = Teisu.flec
local peek = Teisu.peek

local health = flec(100)
print(peek(health)) --> 100

health(50)

print(health()) --> 50
print(peek(health)) --> 50
```

Alternatively, flecs support an `updater` callback that allows you to transform a previous value into a new value:

```luau
health(function(old_health)
    return old_health + 50
end)
```

::: tip Writing to a `flec` returns the value you gave it.

You can edit a flec's value in the middle of calculations:

```luau
local cool_number = flec(0)
local calculation = 10 + cool_number(2 + 2)

print(calculation) --> 14
print(cool_number()) --> 4
```

This is useful for making complex expressions. In most situations; however, it's best to keep your expressions simple.

:::
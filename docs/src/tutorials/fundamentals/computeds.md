# Computeds

In some situations, processing values from flecs can be useful. Computeds can help you get the job done.

## Usage

To create a `computed`, call `Teisu.computed`:

```luau {5-9}
local Teisu = require(game.ReplicatedStorage.Teisu)

local computed = Teisu.computed

local quick_maths = computed(function()
    return (2+2) - 1
end)

print(quick_maths()) --> 3
```

You pass in a callback function that defines a calculation. From there, you can use `peek()` or call the computed itself to read the result of the calculation at any time.

### Using flecs

Calling flecs inside the computed callback will track them as a dependency:

::: code-group

```luau {4} [Luau code]
local numbers = flec({ 1 })

local display_numbers = computed(function()
    return `numbers: {table.concat( numbers(), "," )}`
end)

print(display_numbers())

numbers(function(old)
    local new = table.clone(old)
    table.insert(new, 2)
    return new
end)

print(display_numbers())
```

```luau [Output]
numbers: 1
numbers: 1, 2
```

:::

### Peeking at state objects

However, if you try to `peek()` a `flec` inside the callback, your code won't work as intended:

```luau {9-16}
local numbers = flec({ 1 })

local display_numbers = computed(function()
    return `numbers: { table.concat( peek(numbers), "," ) }`
end)

print(numbers(), display_numbers()) --> { 1 }, numbers: 1

-- `display_numbers` will not rerun!
numbers(function(old)
    local new = table.clone(old)
    table.insert(new, 2)
    return new
end)

print(numbers(), display_numbers()) --> { 1, 2 }, numbers: 1
```

This is where the second argument of `peek()` comes in handy.

If we set this argument to `true`, `numbers` will be tracked as a dependency, and `peek()` will return the result of `numbers`.

```luau {4}
local numbers = flec({ 1 })

local display_numbers = computed(function()
    return `numbers: { table.concat( peek(numbers, true), "," ) }`
end)

print(numbers(), display_numbers()) --> { 1 }, numbers: 1 

-- `display_numbers` will rerun now!
numbers(function(old)
    local new = table.clone(old)
    table.insert(new, 2)
    return new
end)

print(numbers(), display_numbers()) --> { 1, 2 }, numbers: 1, 2
```

::: tip Computed calculations are memoized.
    
If the recalculated value is the same as the old value, the computed callback will return the old value. Effects that depend on the computed will not rerun.

```luau {6-10}
local count = flec(1)
local double_count = computed(function()
    return count() * 2
end)

print(double_count()) --> 2
count(2)
print(double_count()) --> 4
count(2)
print(double_count()) --> 4
```

:::

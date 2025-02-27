# Cleanups

Teisu provides a `cleanup()` function for you to use in situations where you need to clean up side effects from `flec` updates or if you need to destroy a component.

## Usage

If `cleanup()` is called inside a `root()` call, it will schedule a callback *until* the `root` is destroyed:

```luau {4,9-11}
local root = Teisu.root
local effect = Teisu.effect
local flec = Teisu.flec
local cleanup = Teisu.cleanup

local unroot = root(function()
    local truthy = flec(false)
    
    cleanup(effect(function()
        print(`is truthy: {truthy()}`)
    end))
end)

-- destroys the `root` and the effect after 5 seconds
task.delay(5, unroot)
```

However, if `cleanup()` is called outside of a `root()` call, it will clean up whatever you pass into the function **immediately**.

::: code-group

```luau [Luau code]
local function observer(object: any)
    print(`listening to {object}...`)

    return function()
        print("cleaned up!")
    end
end

local connection = observer("joe")

cleanup(connection)
```

```luau [Output]
listening to joe...
cleaned up!
```

:::


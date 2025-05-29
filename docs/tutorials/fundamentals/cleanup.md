# Cleanup

Teisu provides a `cleanup()` function for you to use in situations where you need to clean up side effects from state updates, [Instances](https://create.roblox.com/docs/reference/engine/datatypes/Instance), etc.

## Usage

If `cleanup()` is called inside a scope, it won't run the callback *until* the scope is destroyed:

```luau {5-7}
local root = Teisu.root
local cleanup = Teisu.cleanup

local destroy = root(function()
    cleanup(function()
        print("stable scope destroyed!")
    end)

    print("stable scope created!")
end)

-- destroys the `root` after 5 seconds, and prints 'stable scope destroyed!'
task.delay(5, destroy)
```

However, if `cleanup()` is called outside of a scope, it will clean up whatever you pass into the function **immediately**.

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


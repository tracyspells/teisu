# Molecules

Molecules are selector functions -- functions that select certain aspects of state and returns them.

## What is considered a molecule?

- Computeds

- Flecs

    The read opercation of a `flec` can be considered a molecule.

    ```luau
    local count = flec(0)

    local display_count = function()
        print(`count: {count()}`)
    end

    effect(function()
        display_count()
    end)
    ```

- Functions

    As long as you have a state object that's being read inside a function, that function is considered a `molecule`.

    ```luau {5-7}
    local subscribe = Teisu.subscribe

    local text = flec("hi there reader!")

    local uppercase = function()
        return string.upper(text())
    end

    subscribe(uppercase, function(new)
        print(new)
    end)
    ```



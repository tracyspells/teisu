# Scopes

In Teisu, you create a lot of objects: Instances, signals, connections, threads, etc. These objects need to be destroyed when you're done with them.

Teisu's scopes allow you to do so with a minimal, clean API. With that said, there are things you need to know:

1. There are two types of scopes: stable and reactive.

    - Stable scopes *never* rerun.
    - Reactive scopes can rerun.

    `root()` creates a stable scope under the hood, and `effect()` and `computed()` create a reactive scope.

2. An effect **cannot** be created within a computed object or another effect.

3. Whenever a scope is destroyed, any scope created within that scope is also destroyed.

    It doesn't matter how nested a scope is, it will get cleaned up.

    ```luau
    local flec = teisu.flec
    local effect = teisu.effect
    local root = teisu.root

    local count = flec(0)

    local destroy = root(function()
        effect(function()
            print(count())
        end)
    end)

    while count() < 5 do
        count(function(old)
            return old + 1
        end)

        task.wait(1)
    end

    destroy() -- destroys the reactive scope created by effect()
    ```

4. Reactive scopes don't have to be created underneath a stable scope. 

    Effects and computeds can be used *anywhere*!

    ```luau
    local flec = teisu.flec
    local effect = teisu.effect

    local count = flec(0)

    effect(function()
        print(count())
    end)

    while count() < 5 do
        count(function(old)
            return old + 1
        end)

        task.wait(1)
    end
    ```

Scopes may seem tricky to understand, but they're designed so that as long as you understand the things mentioned above, you won't have to worry about them.

In the next section, you'll learn how to clean up a scope.
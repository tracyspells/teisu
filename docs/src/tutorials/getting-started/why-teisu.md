# Why Teisu?

I wanted to make a reactive library just for fun and to gain experience. 

Not only that, but I wanted to combine two libraries that Teisu is based on:

- [Vide](https://centau.github.io/vide/)

- [Charm](https://github.com/littensy/charm)

...and merge them into one. I added some changes and quality of life improvements.

## Goals

For Teisu, I wanted the library to meet the following requirements:

- Scope Agnostic

    Most of Teisu's API (`flec`, `computed`, `effect`, etc) can be used anywhere without a reactive scope as the prerequisite. 

    ```luau
    local count = Teisu.flec(0)
    local message = Teisu.computed(function()
        local number = count() 
        return `count: {number}, doubled: {number * 2}`
    end)

    local dispose = Teisu.effect(function()
        print(message())
    end)

    while count() < 15 do
        task.wait(1)
        count(count() + 1)
    end

    dispose()
    ```

- Animate anything

    You can use springs/tweens outside of UI!

    ```luau
    local Teisu = require(game.ReplicatedStorage.Teisu)

    local flec = Teisu.flec
    local spring = Teisu.spring

    local cube = Instance.new("Part")
    cube.Anchored = true
    cube.CanCollide = false
    cube.Size = Vector3.new(5, 5, 5)
    cube.CFrame = CFrame.new(0, 0, 0)
    cube.Parent = workspace

    local DEFAULT_CFRAME = cube.CFrame

    local should_rise = flec(false)
    local cubeSpring = spring(function()
        return if should_rise() then DEFAULT_CFRAME * CFrame.new(0, 10, 0) else DEFAULT_CFRAME
    end, 0.3)
    ```

- Replicating state across the server-client boundary should be hassle free.

    All you need to do is plug in your state objects, and Teisu will handle the rest.
# Observers

These helper functions are offshoots of `Teisu.effect` and can be useful in certain situations.

## Listening to state changes

If you would like to strictly detect changes without running the callback immediately, you can use `Teisu.subscribe`:

::: code-group

```luau {10-12} [Luau code]
local Teisu = require(game.ReplicatedStorage.Teisu)

local flec = Teisu.flec
local subscribe = Teisu.subscribe

local count = flec(0)

-- `subscribe` will not run the callback immediately upon initialization
-- it will run when `count` changes
subscribe(count, function(new: number, old: number)
    print(`new count: {new}, old count: {old}`)
end)

count(1)
count(1) --> will not print anything
count(2) 
```

```luau [Output]
new count: 1, old count: 0
new count: 2, old count: 1
```

:::

`subscribe()` returns a function that will disconnect the connection.

```luau {1, 7}
local disconnect = subscribe(count, function(new: number, old: number)
    print(`new count: {new}, old count: {old}`)
end)

-- disconnects the above handler after 5 seconds
task.wait(5)
disconnect()
```

## Track additions and removals

Let's say you're in a situation where you have a `flec` that stores a dictionary/array...

```luau
local test_scores = flec({
    ["Alice"] = 75,
    ["Bob"] = 95,
    ["Joe"] = 62,
    ["Susan"] = 99,
})
```

...and you would like to listen for additions or removals in your table. You can use `Teisu.observe` to accomplish this:

::: code-group

```luau {13-19} [Luau code]
local Teisu = require(game.ReplicatedStorage.Teisu)

local flec = Teisu.flec
local observe = Teisu.observe

local test_scores = flec({
    ["Alice"] = 75,
    ["Bob"] = 95,
    ["Joe"] = 62,
    ["Susan"] = 99,
})

local disconnect = observe(test_scores, function(score: number, person: string)
    print(`added {person}'s score of {score} to the gradebook`)

    return function()
        print(`removed {person}'s score from the gradebook`)
    end
end)

test_score(function(old)
    local new = table.clone(old)
    new["Ezekiel"] = 85
    return new
end)

task.wait(2)

test_score(function(old)
    local new = table.clone(old)
    new["Alice"] = nil
    return new
end)

task.wait(2)
disconnect()
```

```luau [Output]
added Ezekiel's core of 85 to the gradebook
removed Alice's score from the gradebook
```

:::


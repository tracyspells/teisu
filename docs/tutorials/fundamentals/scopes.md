# Scopes

In [Vide](https://centau.github.io/vide/), core reactive functions like `effect()` have to be created inside a stable scope.

```luau
local root = vide.root
local source = vide.source
local effect = vide.effect

local count = source(0)

local function setup()
    effect(function()
        print(count())
    end)
end

setup() -- error, effect() tried to create a reactive scope with no stable scope

local destroy = root(setup) -- ok since effect() was called in a stable scope

count(1) -- prints "1"
count(2) -- prints "2"

destroy()

count(3) -- reactive scope created by effect() is destroyed, it does not rerun
```

This is neat! But...I find this to be a limitation. I wanted a way to use `effect()` without having to deal with this.

So I did.

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

Nice and simple. The inspiration behind this was thanks to [Charm](https://github.com/littensy/charm).

## Why add `Teisu.root` then?

`Teisu.root` is different from `Vide.root` in the sense that the "stable scope" that's created is only used to schedule cleanup functions. Let's take a look at this example:

```luau {8-10}
local flec = teisu.flec
local effect = teisu.effect
local root = teisu.root

local destroy, count = root(function()
    local count = flec(0)

    effect(function()
        print(count())
    end)

    return count
end)

while count() < 5 do
    count(function(old)
        return old + 1
    end)

    task.wait(1)
end

destroy()
```
When the effect (that is highlighted) is created, the function that destroys the effect is scheduled for later deletion. By the time `destroy` is called, we destroy the effect and the stable scope itself.

In the next section, you'll learn how to schedule your own functions for deletion inside a stable scope.

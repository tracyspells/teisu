# Reactivity: Utility

## cleanup()

If called outside a stable scope, it will run the callback immediately. If called inside a stable scope, it queues the callback to run when the scope is destroyed.

```luau
function cleanup(object: Function | Disconnectable | Destroyable | Animatable<unknown> | thread)

type Animatable<T> = Spring<T> | Tween<T>
type Function = () -> ()
type Disconnectable = { Disconnect: Function } | { disconnect: Function }
type Destroyable = { Destroy: Function } | { destroy: Function }
```

### Parameters

-   `object`: An object that can be destroyed.

### Returns

`cleanup()` does not return anything.

**Example:**

```luau

-- runs immediately 
cleanup(function()
    print('hi')
end)

local source = flec(0)

local unroot = root(function()
    cleanup(function()
        print('cleaned')
    end)

    effect(function()
        print(`{source()}`)
    end)
end)

source(1)
source(2)
unroot() -- prints 'cleaned' and destroys the effect 
```

## peek()

A utility function that calls a function without tracking it as a dependency of an effect or a computed object.

```luau
function peek<T>(value: T | () -> T, dont_untrack: boolean?): T
```

### Parameters

-   `value`: Any value. If the value is a function, `peek` will call it without tracking any dependencies and returns the result.

-  **optional** `dont_untrack`: If this is set to true and `value` is a function, `peek` will call the function, allowing dependencies to be tracked and returns the result. Defaults to `false`.

### Returns

`peek` returns the result of the given function. If `value` is not a function, it will return the value as-is.

**Example:**

```luau
local nameFlec = flec("Alice")
local ageFlec = flec(21)
local dislikesFlec = flec({ "hockey", "fish", "tarantulas" })

effect(function()
	local name = nameFlec()
	local age = peek(ageFlec)
    local dislikes = peek(dislikesFlec, true) -- allows the `dislikesFlec` to be tracked as a dependency
end)
```


## batch()

Defers state changes until after the callback has ran. This is useful when you need to make multiple changes to the state and only want effects and computeds to be notified once.

```luau
function batch(callback: () -> ()): ()
```

### Parameters

-   `callback`: A function that updates atoms. Effects and computeds will only be notified once all changes have been applied.

### Returns

`batch` does not return anything.


**Example:**

```luau
local a = flec(0)
local b = flec(0)

effect(function()
    print(a() + b())
end)

-- prints "0"

batch(function()
    a(1) -- no print
    b(2) -- no print
end)

-- prints "3"
```

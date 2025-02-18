# Reactivity: Core

## flec()

Creates a new flec.

```luau
function flec<T>(state: T): Flec<T>
function flec<T>(state: T, equals: (T, T) -> boolean): Flec<T>

type Flec<T> = 
    () -> T -- get
    & (T) -> () -- set
```

### Parameters

-   `state`: The value to assign the flec initially.

-  **optional** `equals`: An optional equality function to determine whether `state` should change. Defaults to reference equality (`==`).

### Returns

The `flec` constructor returns a function that does two possible operations:

1. **Get its state.** Call the `flec` without any arguments to retrieve its current state.
2. **Set its state.** Pass in a new value or an updater function to change the state.

**Example:**

```luau
local todosFlec = flec({ "fall asleep" })
local count = flec(0)

-- getting the state
print(count()) -- 0

-- setting the state
count(count() + 1 )

print(count()) -- 1

-- supports an updater function
todosFlec(function(todos)
    -- we can't `table.insert` without making a copy of `todos`
    -- because of reference equality
    todos = table.clone(todos)
    table.insert(todos, "buy milk")

    return todos
end)

print(todosFlec()) -- { "fall asleep", "buy milk" }
```

## computed()

Derives a new, read-only flec from one or more flecs.

```luau
function computed<T>(callback: () -> T): () -> T
function computed<T>(callback: () -> T, equals: (T, T) -> boolean)
```

`computed` will cache the result to prevent recomputations on every read.

::: danger
Computed calculations should be immediate and <u>never delay</u>. You should never use a `computed` when you need to wait for something to happen (e.g. waiting for a server to respond to a request).
:::

### Parameters

-   `callback`: A function that returns a new value depending on one or more flecs.

-  **optional** `equals`: An optional equality function to determine whether `state` should change. Defaults to reference equality (`==`).

### Returns

`computed` returns a read-only flec.

**Example:**

```luau
local todos: Flec<{ string }> = flec({})
local mapToUppercase = computed(function()
	local result = table.clone(todos())
	for key, todo in result do
		result[key] = string.upper(todo)
	end
	return result
end)

todos(function(todos)
    todos = table.clone(todos)
    table.insert(todos, { "play wii sports resort" })
    return todos
end)

print(mapToUppercase()) -- { "PLAY WII SPORTS RESORT" }
```

## effect()

Tracks state changes in one or more dependencies read within the callback.

```luau
type Cleanup = () -> ()

function effect(callback: () -> ()): Cleanup
function effect(callback: ( cleanup: Cleanup ) -> ()): Cleanup
```

::: danger
Effects should <u>never delay</u>. You shouldn't use an `effect` when you need to wait for something to happen (e.g. waiting for a server to respond to a request).
:::

### Parameters

-   `callback`: The function to track for state changes. The callback will run once to retrieve its dependencies, and then again whenever they change.

### Returns

`effect` returns a function that destroys the effect.

**Example:**

```luau
local source = flec("Hello, world!")
local dispose = effect(function()
    print(`{source()}`)
end)

source("Goodbye, world!") -- Goodbye, world!
dispose() -- destroys the effect
```

### Cleanups

A special `cleanup` function is passed in to the `effect` callback. Functions passed as an argument to this `cleanup` function will run:

1. Before each re-invocation of the `effect` callback (i.e. when one or more dependencies change)
2. When the `effect` itself is destroyed (if there were any functions scheduled, they will run on effect destruction)

**Example Usage:**

```luau
local count = flec(0)
local dispose = effect(function(cleanup)
    cleanup(function()
        print("count has changed!")
    end)

    print(`{count()}`)
end)

count(count() + 1) -- prints `count has changed!`, and then `1`
count(count() + 1) -- prints `count has changed!`, and then `2`
dispose() -- will not print anything
```


## root()

Runs a callback in a stable scope.


```luau
type Cleanup = () -> ()

function root<T...>(callback: () -> T...): (Cleanup, T...)
```

### Parameters

-   `callback`: The function to run. This function may return any value(s).

### Returns

`root` returns a cleanup function and any values returned by the callback.

**Example:**

```luau
local unroot, source = root(function()
    local messageFlec = flec("Hello, world!")

    cleanup(effect(function()
        print(`{messageFlec()}`)
    end))

    return messageFlec
end)

source("Goodbye, world!") -- prints "Goodbye, world!"
unroot() -- destroys the scope and cleans up the effect
```



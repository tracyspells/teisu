# Reactivity: Observers

## subscribe()

Listens for changes in a flec or a molecule.

```luau
type Molecule<T> = () -> T

type Cleanup = () -> ()

function subscribe<T>(state: Molecule<T>, listener: (new: T, old: T) -> ()): Cleanup
```

### Parameters

-   `state`: The flec or molecule to subscribe to. 

-   `listener`: A function that is called whenever the result of `state` changes. It receives the new state and previous state as arguments. 


### Returns

`subscribe` returns a cleanup function.

**Example:**

```luau
local count = flec(0)
local unsubscribe = subscribe(count, function(new, old)
    print(`{new, old}`)
end)

count(count() + 1) -- prints `1, 0`
unsubscribe() -- disconnects the listener
```

## observe()

Listens for additions or deletions in a dictionary or an array.

```luau
type Map<K, V> = { [K]: V }

type Cleanup = () -> ()

type Molecule<T> = () -> T
type MapMolecule<K, V> = Molecule<Map<K, V>>

function observe<K, V>(subject: MapMolecule<K, V>, factory: (value: V, key: K) -> ()): Cleanup
function observe<K, V>(subject: MapMolecule<K, V>, factory: (value: V, key: K) -> Cleanup): Cleanup
```

::: tip
Because `observe` tracks the lifetime of each key in your data, your keys must be unique and unchanging.
:::

### Parameters

-   `subject`: The flec or molecule that returns either a dictionary or an array of values. When a key is added, `factory` is called with the new key and its initial value. 

-   `factory`: A function that is called whenever a key is added or deleted from the flec's (or molecule's) state. It receives the key and the entry's initial value as arguments, and may return a cleanup function. 


### Returns

`observe` returns a cleanup function.

**Example:**

```luau
type Todo = { name: string }

local todos: Flec<{ [string]: Todo }> = flec({})

local stopObserving = observe(todos, function(todo, key)
	print(`Added {key}: {todo.name}`)
	return function()
		print(`Removed {key}`)
	end
end)
```


# Reactivity: Dynamic

## mapped()

Transforms the keys and values of your state.

```luau
type Map<K, V> = { [K]: V }

type Cleanup = () -> ()

type Molecule<T> = () -> T
type MapMolecule<K, V> = Molecule<Map<K, V>>

function mapped<K0, V0, V1>(state: MapMolecule<K0, V0>, mapper: (V0, K0) -> V1?): MapMolecule<K0, V1>
function mapped<K0, V0, K1, V1>(state: MapMolecule<K0, V0>, mapper: (V0, K0) -> (V1?, K1?)): MapMolecule<K1, V1>
function mapped<K0, V0, K1, V1>(state: MapMolecule<K0, V0>, mapper: (V0, K0) -> (V1?, K1)): MapMolecule<K1, V1>
```

### Parameters

-   `state`: A molecule that returns a dictionary or an array that you want to map over.

-   `mapper`: A function that is called for each key and value in your `state`. For each key and value, this function will return a new value and key:

    1. Return a single value to map your `state`'s original key to a new value.
    2. Return two values, the first being the value and the second the key, to update both keys and values in your `state`.
    3. Return `nil` for the value to remove the key from the resulting `state`.


### Returns

`mapped` returns a read-only flec.

**Example:**
```luau
type Todo = { id: number, value: string }

local todosFlec: Flec<{ Todo }> = flec({})
local todosById = mapped(todosAtom, function(todo, index)
	return todo.value, todo.id
end)
```

## show()

Displays components once a certain condition is met.

```luau
type Molecule<T> = () -> T
type Derivable<T> = (Molecule<T>) | T

function show<T>(input: Derivable<unknown>, component: () -> T): T?
function show<T, U>(input: Derivable<unknown>, component: () -> T, fallback: () -> U): (T | U)?
```

### Parameters

-   `input`: A derivable that returns a truthy value that determines what component to display.

-   `component`: A callback that returns a component that will display if `input` returns true.

-   **optional** `fallback`: A callback that returns a component that will display if `input` returns false.


### Returns

1. If the result from `input` is set to `nil`, the output of `show` is `nil`.
2. If the result from `input` is set to `true`, `show` will return the result from `component`.
2. If `fallback` is enabled and the result from `input` is set to `false`, `show` will return the result from `fallback`.

**Example:**

```luau
local source = flec(true)

local function truth_text()
    return new "TextLabel" {
        Text = "The other text is a liar..."
    }
end

local function lie_text()
    return new "TextLabel" {
        Text = "The other text sure ain't a truther!"
    }
end

local function app()
    return new "ScreenGui" {
        show(source, truth_text, lie_text)
    }
end

mount(app, Players.LocalPlayer.PlayerGui)

task.delay(2, function()
    source(false)
end)
```

## switch()

Displays a component out of a list of components given an input and a mapping table.

```luau
type Molecule<T> = () -> T
type Derivable<T> = (Molecule<T>) | T

function switch<K, V>(source: Derivable<K>): (map: Map<K, () -> V>): () -> V?
```

### Parameters

-   `source`: A derivable that returns a value that can be inputed onto the `map` to get a component constructor. This component is then ran inside a stable scope. Each time `source` updates, previous scopes get destroyed.

### Returns

`switch` returns a read-only flec containing an instance of the current component shown, or `nil` if no component is currently shown.

**Example:**
```luau
local input = flec(false)

local function truth_text()
    return new "TextLabel" {
        Text = "The other text is a liar..."
    }
end

local function lie_text()
    return new "TextLabel" {
        Text = "The other text sure ain't a truther!"
    }
end

local text = switch(input) {
    [true] = truth_text,
    [false] = liar_text,
}

local function app()
    return new "ScreenGui" {
        text
    }
end

mount(app, Players.LocalPlayer.PlayerGui)

task.delay(2, function()
    source(false)
end)
```
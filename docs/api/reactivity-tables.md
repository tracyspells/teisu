# Reactivity: Tables

::: tip When should I use `indexes`, `keys`, and `values`?
<!--@include: @tutorials/tables/when-should-i-use-what.md{2,11}-->
:::

## values()

Transforms the values of your state.

```luau
type Map<K, V> = { [K]: V }

type Cleanup = () -> ()

type Molecule<T> = () -> T
type Derivable<T> = (Molecule<T>) | T

type MapMolecule<K, V> = Molecule<Map<K, V>>

function values<K0, V0, V1>(
    state: Derivable<Map<K0, V0>>, 
    mapper: (Molecule<V0>, K0) -> V1
): MapMolecule<K0, V1>
```

### Parameters

-   `state`: A [derivable](../tutorials/fundamentals/derivable) that represents a dictionary or an array that you want to map over.

-   `mapper`: A function that is called for each key and value in your `state`. The mapper can return a value.


### Returns

`values` returns a read-only flec.

::: details Implementation details
 - For keys that are added to `state`, a stable scope is created once to schedule cleanup functions, and the `mapper` function gets called and returns the new value.
   - If the value returned from the `mapper` function is an Instance, it will be cached until the original key is removed.
 - For keys that are removed from `state`, the stable scope is destroyed.
 - Any time an existing key's value changes:
   - If the `mapper` initially returned an Instance, only the molecule (the first argument in the `mapper` callback) will update with the new value.
   - If the `mapper` initially returned a non-Instance (tables, strings, numbers, etc.), `mapper` will be called with the updated molecule (the first argument in the `mapper` callback).
:::

**Examples:**

::: code-group
```luau [Example A]
local test = flec({ 1, 2, 3 })
local double = values(test, function(number, _index) 
   return number() * 2
end)

print(double()) --> { 2, 4, 6 }
```

```luau [Example B]
local source = { "i'm the strongest there is!" }
local all_uppercase = values(source, function(value) 
   return string.upper(value())
end)

print(all_uppercase()) --> { "I'M THE STRONGEST THERE IS!" }
```

```luau [Example C]
type Item = { name: string, description: string }

local function item_display(item: () -> Item, i: number)
    local item_desc = computed(function()
        local data = item()
        return data.description
    end)

    local item_name = computed(function()
        local data = item()
        return data.name
    end)

    return new "TextLabel" {
        Text = item_desc,
        Name = function()
            return `{i}: {item_name()}`
        end,
    }
end

local items = flec({} :: { Item })

local item_displays = values(items, function(item, i) 
   return item_display(item, i)
end)
```
:::

## indexes()

Transforms the values of your state.

```luau
type Map<K, V> = { [K]: V }

type Cleanup = () -> ()

type Molecule<T> = () -> T
type Derivable<T> = (Molecule<T>) | T

type MapMolecule<K, V> = Molecule<Map<K, V>>

function indexes<K0, V0, V1>(
    state: Derivable<Map<K0, V0>>, 
    mapper: (V0, Molecule<K0>) -> V1
): MapMolecule<K0, V1>
```

::: warning Duplicate values
Having the same values appear multiple times in the input `flec` table can cause unexpected behavior. [`Teisu.strict`](../api/teisu/#strict), if enabled, can check for duplicate values and can let you know right away.
:::

### Parameters

-   `state`: A [derivable](../tutorials/fundamentals/derivable) that represents a dictionary or an array that you want to map over.

-   `mapper`: A function that is called for each key and value in your `state`. The mapper can return a value.


### Returns

`indexes` returns a read-only flec.

::: details Implementation details
 - For indexes that are added to `state`, a stable scope is created once to schedule cleanup functions, and the `mapper` function gets called and returns the new value.
   - If the value returned from the `mapper` function is an Instance, it will be cached until the original key is removed.
 - For indexes that are removed from `state`, the stable scope is destroyed.
 - Any time an existing value's index changes:
   - If the `mapper` initially returned an Instance, only the molecule (the second argument in the `mapper` callback) will update with the new index.
   - If the `mapper` initially returned a non-Instance (tables, strings, numbers, etc.), `mapper` will be called with the updated molecule (the second argument in the `mapper` callback).
:::

**Examples:**

::: code-group
```luau [Example A]
local todos = flec({ "go shopping", "eat food", "head back home" })

local numbered_todos = indexes(todos, function(value, index)
    return `{index()}. {value}`
end)
```

```luau [Example B]
type Item = { name: string, description: string }

local function item_display(item: Item, i: () -> number)
    return new "TextLabel" {
        Text = item.description,
        Name = function()
            return `{i()}: {item.Name}`
        end,
    }
end

local items = flec({} :: { Item })

local item_displays = indexes(items, function(item, i) 
   return item_display(item, i)
end)
```
:::

## keys()

Transforms the keys of your state.

```luau
type Map<K, V> = { [K]: V }

type Cleanup = () -> ()

type Molecule<T> = () -> T
type Derivable<T> = (Molecule<T>) | T

type MapMolecule<K, V> = Molecule<Map<K, V>>

function keys<K0, V0, V1>(
    state: Derivable<Map<K0, V0>>, 
    mapper: (V0, K0) -> K1
): MapMolecule<K1, V0>
```

### Parameters

-   `state`: A [derivable](../tutorials/fundamentals/derivable) that represents a dictionary, set or an array that you want to map over.

-   `mapper`: A function that is called for each key in your `state`. The mapper can return a key.


### Returns

`keys` returns a read-only flec.

**Example:**

```luau 
local data = flec({ foo = "bar", bar = "bazz" })

local uppercase = keys(data, function(key)
    return string.upper(key)
end)

print(uppercase()) --> { FOO = "bar", BAR = "bazz" }
```
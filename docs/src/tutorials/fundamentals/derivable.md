# Derivable

`Derivable` is a type that combines a molecule:

```luau
type MoleculeThatReturnsAString = () -> string
```

and a constant:

```luau
type Constant = string
```

into one. This is what a `Derivable` looks like internally:

```luau
type Derivable<T> = T | () -> T
```


## Usage

Say you have a table like so:

```luau
type Props = {
    count: Molecule<number>
}

local props: Props = { count = flec(0) }

print(peek(props.count))
```

And you want your `peek` to detect constants as well as state objects. You can do so by doing this:

```luau {2}
type Props = {
    count: Derivable<number>
}

local props: Props = { count = flec(0) }

print(peek(props.count)) --> 0
```

By setting `count`'s value type to `Derivable<number>`, we can do something like:

```luau {1}
props.count = 0

print(peek(props.count)) --> 0
```

and the code will still work as expected. Pretty neat, huh?

::: warning Be mindful of `Derivable` angle brackets

Consider the following type definitions carefully:

```luau
Derivable<Vector3>?
```

This type definition means that it will only accept:

- `Vector3`

- A molecule that returns a `Vector3` object

- `nil` (if the user doesn't specify a property value)

This type is best used for *optional properties*, where you provide a default value if not specified by the user. 

```luau
Derivable<Vector3?>
```

This type definition means that it will only accept:

- `Vector3`, or `nil`

- A molecule that returns a `Vector3` object, or `nil`

This type works best in situations where the property understands `nil` as a valid value. The user can set it to `nil` at any time.

:::


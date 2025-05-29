# Element Creation

## new()

Creates a new UI element.

```luau
type Map<K, V> = { [K]: V }

type Properties = Map<string|number, unknown>

function new(class: string): (Properties) -> Instance
function new(instance: Instance): (Properties) -> Instance
```

::: tip Property Setting Rules

1. If the index is a string...

   -   ...and the value is a function:
        -  **property is event**: connects function as callback
        -  **property is not an event**: creates an effect to update property
    
   -   ...and the value is not a function:
        -  **if the value is a spring/tween object**: creates an effect to update property

        Otherwise it will set the property to the value.

2. If the index is a number...

    -   **...and the value is an action**: runs the action
    -   **...and the value is a table**: recurses the table
    -   **...and the value is an Instance**: sets the instance as the child.
:::

::: danger
You cannot call `new` outside of a scope.
:::

### Parameters

`new` can either take a `string` or an `Instance` as its first argument:

1. If given a `string`, a new instance with the same class name will be created.
2. If given an `Instance`, a clone of said instance is created. Properties will be applied to the cloned instance.

### Returns

`new` returns a new UI element.

**Example:**

```luau
local frame = new "Frame" {
    Name = "A cool frame",
    BackgroundTransparency = 1,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromScale(0.2, 0.2),
    Position = UDim2.fromScale(0.5, 0.5),

    new "TextLabel" {
        Size = UDim2.fromScale(1, 1),
        Text = "Say whaaat?!"
    }
}
```


## action()

Creates an object that can be used in `new()` to invoke custom actions on instances.

```luau
function action(fn: (Instance) -> ()): Action
```

### Parameters

-   `fn`: A callback that allows you to perform custom actions on an instance.


### Returns

`action` returns an object.

**Example:**

```luau
local flec = teisu.flec
local action = teisu.action
local new = teisu.new

local function changed(property: string, fn: (new) -> ())
    return action(function(instance)
        local connection = instance:GetPropertyChangedSignal(property):Connect(function()
            fn(instance[property])
        end)

        -- disconnect on scope destruction to allow gc of instance
        cleanup(connection)
    end)
end

local output = flec("")

new "TextBox" {

    -- will update the output source anytime the text property is changed
    changed("Text", output),
}
```

## changed()

A wrapper for `action()` to use to track property changes.

```luau
function changed<T>(property: string, listener: (value: T) -> ()): Action
```

### Parameters

-   `property`: The property name of the `Instance` you want to track changes.

-   `listener`: A function that runs immediately and whenever `property` changes.

### Returns

`changed` returns an `action` object.


## mount()

Runs a new function in a stable scope, and optionally applies its result to a target instance.

```luau
type Cleanup = () -> ()

function mount<T>(component: () -> T, target: Instance?): Cleanup
```

### Parameters

-   `component`: A function that returns a UI element.

-  **optional**  `target`: The instance you want to mount your `component` to.

### Returns

`mount` returns a cleanup function that destroys the stable scope.


**Example:**

```luau
local player = Players.LocalPlayer

local function app()
    return new "ScreenGui" {
        new "TextLabel" {
            Text = "Bobby was here!"
        }
    }
end

local destroy = mount(app, player.PlayerGui)
```
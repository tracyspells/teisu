# Components

Components are the building blocks of UI programming. They're reusable functions that returns a piece of UI, and that piece can be used to be apart of something much bigger.

For example, this component below creates a button based on properties the user passes in:

```luau [Button.luau]
local new = Teisu.new

local function button(props: {
    Position: UDim2,
    Text: string,
    OnClick: () -> ()
})
    return new "TextButton" {
        Position = props.Position,
        Text = props.Text,
        Size = UDim2.fromOffset(250, 50),
        Activated = function()
            props.OnClick()
        end,
    }
end

return button
```

From there, we can use our button component anywhere:

```luau [App.client.luau]
local new = Teisu.new

local button = require(Button)

local screen_gui = new "ScreenGui" {
    Name = "App",
    Parent = Players.LocalPlayer.PlayerGui,

    button({ 
        Text = "Hello, world!",
        Position = UDim2.fromScale(0.5, 0.5),
        OnClick = function()
            print("You clicked me!")
        end,
    })
} 
```

## Properties

It's important that you declare what `props` contains in order to build your components. You can provide a type to `props` that outlines your list of properties:

```luau {2-6}
local function cheese(
    props: {
        Size: Vector3,
        Color: Color3,
        IsStinky: boolean,
    }
)

    -- ...other stuff here...
end
```
 
Okay, that's cool and dandy, but what if you want your `props` to support state objects? 

Don't worry, we can use the `Derivable` type for this.


```luau {5-7}
type Derivable<T> = Teisu.Derivable<T>

local function cheese(
    props: {
        Size: Derivable<Vector3>,
        Color: Derivable<Color3>,
        IsStinky: Derivable<boolean>,
    }
)

    -- ...other stuff here...
end
```

Now with this implemented, you can use `peek()` to determine whether a property is a state object or not.

```luau
local peek = Teisu.peek
local flec = Teisu.flec

local function cheese(
    props: {
        Size: Derivable<Vector3>,
        Color: Derivable<Color3>,
        IsStinky: Derivable<boolean>,
    }
)

    local size = peek(props.Size)
    local color = peek(props.Color)

    print(size) --> {1, 0, 1, 0}, is a state object
    print(color) --> [255, 255, 255], not a state object
end

local cheese_size = flec(UDim2.fromScale(1, 1))
cheese({
    Size = cheese_size,
    Color = Color3.fromRGB(255, 255, 255),
    IsStinky = true,
})
```

::: warning Be mindful of `Derivable`'s angle brackets

Consider the following type definitions carefully:

```luau
Derivable<Vector3>?
```

This type definition means that it will only accept:

- `Vector3`

- A state object storing a `Vector3` object

- `nil` (if the user doesn't specify a property value)

This type is best used for *optional properties*, where you provide a default value if not specified by the user. 

```luau
Derivable<Vector3?>
```

This type definition means that it will only accept:

- `Vector3`, or `nil`

- A state object storing a `Vector3` object, or `nil`

This type works best in situations where the property understands `nil` as a valid value. The user can set it to `nil` at any time.

:::

In the next section, you'll learn how to make your components reactive.

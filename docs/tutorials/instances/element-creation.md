# Element Creation

Creating UI elements is a straightforward process. Teisu provides a `new` function which allows you to create an UI element and apply some properties to it.

## Usage

Call `new()` with the type of instance, then pass in a property table like so:

```luau {3-7}
local new = Teisu.new

local frame = new("Frame")({
    BackgroundColor3 = Color3.new(1, 0, 0),
    BackgroundTransparency = 0.5,
    Size = UDim2.fromOffset(250, 50),
})
```

If you want, you can also omit the parentheses `()`:

```luau {3,7}
local new = Teisu.new

local frame = new "Frame" {
    BackgroundColor3 = Color3.new(1, 0, 0),
    BackgroundTransparency = 0.5,
    Size = UDim2.fromOffset(250, 50)
}
```

## Parenting Children

You can pass in child UI elements inside your property table:

```luau {5-11}
local frame = new "Frame" {
    BackgroundTransparency = 1,
    Size = UDim2.fromScale(1, 1),

    new "TextLabel" {
        Text = "Hi!",
        TextSize = 32,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        BackgroundTransparency = 1,
    }
}
```

Parenting existing instances is as easy as 1, 2, 3!

```luau {7}
local part = Instance.new("Part")
part.Size = Vector3.one * 500
part.CanCollide = false

local model = new "Model" {
    Name = "Block",
    part,
}
```

If you want to parent children, arrays of children are allowed:

```luau
local folder = new "Folder" {
    new "Part" {
        Name = "Joe",
        Anchored = true,
    },

    new "Part" {
        Name = "Tommy",
        Anchored = false,
        Material = Enum.Material.Neon,
    },
}
```

Arrays can be nested to any depth, all children will still get parented:

```luau
local model = new "Model" {
    Name = "Cool",
    {
        {
            {
                new "Part" {
                    Name = "Very cool, dude!",
                    Size = Vector3.one * 2,
                }
            }
        }
    }
}
```

Molecules that return an instance will be tracked with an `effect`:

```luau
local source = flec(true)

local part = computed(function()
    local should_display = source()

    if should_display then
        local part = Instance.new("Part")
        part.Name = "Cool Part"
        part.Size = Vector3.new(10, 10, 10)
        part.Anchored = true

        return part
    end

    return nil
end)

local model = new "Model" {
    Name = "Container",
    part,
}
```


## Events

To connect an event, assign a function to a property key that supports the event (i.e., `Activated`).

```luau {5-7}
local button = new "TextButton" {
    Position = UDim2.fromScale(0.5, 0.5),
    AnchorPoint = Vector2.new(0.5, 0.5),
    Size = UDim2.fromOffset(250, 50),
    Activated = function()
        print("Clicked"!)
    end,
}
```
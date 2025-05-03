# Show

`show()` is a state object that displays a component when a certain condition is met.


## Usage

To create a `show` object, call `Teisu.show()` and pass in an input molecule that returns a truthy statement and a component.

```luau {49-54}
type Derivable<T> = Teisu.Derivable<T>

local flec = Teisu.flec
local show = Teisu.show

local function Button(
    props: {
        Position: Derivable<UDim2>,
        Text: Derivable<string>,
        OnClick: (() -> ())?,
    }
)
    return new "TextButton" {
        Text = props.Text,
        Position = props.Position,
        Activated = function()
            if props.OnClick ~= nil then
                props.OnClick()
            end
        end
    }
end

local function Text(
    props: {
        Position: Derivable<UDim2>,
        Text: Derivable<string>,
    }
)
    return new "TextLabel" {
        Position = props.Position,
        AnchorPoint = Vector2.new(0.5, 0.5)
        Text = props.Text,
    }
end

local function Menu()
    local clicked = flec(false)

    return new "Frame" {
        Button {
            Position = UDim2.fromScale(0.5, 0.5),
            Text = "Click me!",
            OnClick = function()
                clicked(not clicked())
            end,
        }

        show(clicked, function()
            return Text {
                Position = UDim2.fromScale(0.5, 0.55),
                Text = "Hi there!"
            }
        end)
    }
end
```

In this example, when `clicked` is set to `true`, a `TextLabel` appears. If `clicked` is set to `false`, the`TextLabel` will get destroyed... unless you provide a fallback option.

```luau {9-14}
 show(
    clicked, 
    function()
        return Text {
            Position = UDim2.fromScale(0.5, 0.55),
            Text = "You got a 20 dollar Steam gift card!"
        }
    end,
    function()
        return Text {
            Position = UDim2.fromScale(0.5, 0.55),
            Text = "Click on the button above for a surprise! ;)"
        }
    end
)
```

# Actions

Actions are special events that you can use to make your UI tree more reactive.

## Usage

To use an action, call `Teisu.action` and pass in a callback:

::: code-group

```luau [Luau code] {7-9}
local action = Teisu.action
local new = Teisu.new

local text_label = new "TextLabel" {
    Text = "Hello, world!"

    action(function(instance)
        print(instance.Text)
    end)
}
```

```luau [Output]
Hello, world!
```

:::

In the next section, you'll discover a provided action that allows you to track property changes.
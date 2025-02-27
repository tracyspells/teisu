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

## Detecting Property Changes

Teisu provides the `changed` action, which allows you to listen for property changes on the parent instance.

::: code-group

```luau [Luau code] {10-12}
local changed = Teisu.changed
local new = Teisu.new
local flec = Teisu.flec

local text = flec("Hello, world!")

local text_label = new "TextLabel" {
    Text = flec,

    changed("Text", function(text: string)
        print(text)
    end)
}

task.wait(2)
text("Goodbye!")

```

```luau [Output]
Hello, world!
(..2 seconds later)
Goodbye!
```
:::

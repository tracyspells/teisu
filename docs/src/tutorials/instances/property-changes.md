# Detecting Property Changes

Teisu provides the `changed` action, which allows you to listen for property changes on the parent instance.

## Usage

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
# Switch

`switch()` displays a component based on a list of conditions.

## Usage

Call `Teisu.switch()` and pass in a input molecule, along with the components you want to display if a condition is met.

```luau {6-14}
local flec = Teisu.flec
local switch = Teisu.switch

local is_true = flec(false)

local result = switch(is_true) {
    [true] = function()
        return "hello!"
    end,

    [false] = function()
        return "goodbye!"
    end,
}

print(result()) --> goodbye!
is_true(true)
print(result()) --> hello!
```
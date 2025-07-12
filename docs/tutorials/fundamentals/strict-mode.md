# Strict Mode

Teisu provides a strict mode functionality to help you identify bugs in your project.

Strict mode is disabled by default. If you'd like to enable it, you can do so by doing the following:

```luau
local Teisu = require("path/to/teisu")

Teisu.strict(true)
```

## Features

Right now, strict mode provides better error handling when processing reactive functions (flecs, computeds, effects) and batching functions.

Errors will provide the function's name and line number, and yielding in reactive functions (except [async](../../api/reactivity-core#async)) will throw an error.

Example:

```luau
local effect = Teisu.effect
local flec = Teisu.flec

local count = flec(0)

effect(function()
    local count_now = count()
    task.wait(2) -- [!code error] no yielding allowed!!
    print(count_now)
end)

```

## Summary

Enabling strict mode in unit tests, storybooks, and other development enviroments can help you catch issues with your code early on. Remember to disable it in production to avoid the performance overhead.


# Teisu

## strict()

Sets or reads the currently stored value for strict mode (click [here](../tutorials/fundamentals/strict-mode) for more details).

```luau
function strict(): boolean
function strict(value: boolean): boolean
```

### Parameters

-  **optional** `value`: A boolean to toggle strict mode.

### Returns

`strict` returns a boolean that represents whether strict mode is enabled.


## step()

Manually steps animations and state syncing.

```luau
function step(delta_time: number): ()
```

::: tip

In most situations, calling `step` is not necessary as it's automatically called every `Heartbeat`.

However, you can utilize `step` if you need more control. It is *highly* recommended that you call this on `RunService.Heartbeat` on the client and or the server.
:::

### Parameters

-  `delta_time`: Time (in seconds) elapsed since the last frame.

### Returns

`step` does not return anything.

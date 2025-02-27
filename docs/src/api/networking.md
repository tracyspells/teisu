# Networking

## SyncPayload

An object that contains important information regarding state.

```luau
type NONE = { __none = "__NONE" }

type Patch<K, V> = {
    op: ("add" | "remove" | "replace"),
    path: { K },
    value: V | NONE,
}

type SyncPayload = {
    type: "init",
    data: { [string | number]: any },
} | {
    type: "patch",
    data: { Patch<string | number, any> },
}
```

### Details

-   When `.type` is set to `init`, `data` represents the entire state of the `flecs` map. This is the "hydration" phase (i.e., when a player joins the game, the server sends a `SyncPayload` to the player).

-   When `.type` is set to `patch`, `data` represents an array of `Patch` objects.  These `Patch` objects represent state changes, and each one contains the following:

    -   `op`: Shorthand for `operation`. Has three modes:

        -   `add`: A new table key has been added.

        -   `replace`: A table key has been changed.

        -   `remove`: A table key has been removed.
    
    -   `path`: An array of table keys that have changed.

    -   `value`: the value that got changed. If `op` is set to `remove`, this will be set to `NONE` (represents nil in Luau).


**Examples:**

::: code-group

```luau [hydration]
local initial_state = {
    foo = flec({ bar = 1 }),
    buzz = flec(2)
}

local syncPayload = {
    type = "init",
    data = {
        foo = { bar = 1 },
        buzz = 2,
    }
}
```

```luau [patch]
local state_that_got_changed = {
    foo = {
        bar = 2
    },

    buzz = nil
},

local syncPayload = {
    type = "patch",
    data = {
        {
            op = "replace",
            path = { "foo", "bar" },
            value = 2,
        },

        {
            op = "remove",
            path = { "buzz" },
            value = NONE,
        }
    }
}
```
:::


## is_none()

Checks if the value given is `NONE`, a special object that represents `nil` in Luau.

```luau
function is_none(value: any): boolean
```

### Parameters

-   `value`: Any value. If the value is `NONE`, `is_none` will return `true`.

### Returns

`is_none()` returns a boolean value.

**Example:**

```luau
local input = 2

print(is_none(input)) -- false

input = NONE

print(is_none(input)) -- true
```

   
## server()

Creates a server sync object. This synchronizes every client's flecs with the server's state by sending state changes that the client then merges into its state.

```luau
type Cleanup = () -> ()

type Map<K, V> = { [K]: V }
    
type Server = {
    hydrate: (self: Server, player: Player) -> (),
    connect: (self: Server, callback: (Player, SyncPayload) -> ()) -> Cleanup,
}

function server({
    flecs: Map<string | number, Flec<any>>,
    interval: number,
}): Server
```

### Parameters

-   `options`: An object to configure sync behavior.

    -   `flecs`: A dictionary of the flecs to sync. The keys should match the keys on the client.

    -   **optional** `interval`: The interval at which to batch state updates to clients. Defaults to `0`, meaning updates are batched every frame.

### Returns

`server` returns an object with the following methods:

-   `:hydrate(player)`: Sends the player a full state update for all synced flecs.

-   `:connect(callback)`: Registers a callback to send state updates to clients. The callback will receive the player and the payload to send, and should fire a remote event. The payload is read-only, so any changes should be applied to a copy of the payload.

**Example:**

```luau
local remotes = require(ReplicatedStorage.Remotes)

local flecs = {
    points = flec(0),
    game_ended = flec(false),
}

local syncer = Teisu.server({flecs = flecs })

syncer:connect(function(player, payload)
    -- send our initial state and state changes to the client
    remotes.sync:fire(player, payload)
end)

remotes.hydrate:connect(function(player: Player)
    -- our player has finished loading in on their end
    -- let's register them
    syncer:hydrate(player)
end)
```


## client()

Creates a client sync object. This synchronizes the client's flecs with the server's state by merging state changes sent by the server into each flec.

```luau
 function client({
        flecs: Map<string | number, Flec<any>>,
    }): Client

    type Map<K, V> = { [K]: V }

    type Client = {
	    sync: (self: Client, payload: SyncPayload) -> (),
    }
```

### Parameters

-   `options`: An object to configure sync behavior.

    -   `flecs`: A dictionary of the flecs to sync. The keys should match the keys on the server.


### Returns

`client` returns an object with the following methods:

-   `:sync(payload)`: Applies a state update from the server.

**Example:**

```luau
local remotes = require(ReplicatedStorage.Remotes)

local flecs = {
    points = flec(0),
    game_ended = flec(false),
}

local syncer = Teisu.client({flecs = flecs })

-- receive state changes from the server and syncs them
remotes.sync:connect(function(payload)
    syncer:sync(payload)
end)

-- ...somewhere far away...
remotes.hydrate:fire() -- let the server know that we loaded in
```
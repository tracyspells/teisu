# Server-Client Sync

In this tutorial, you'll learn how to sync your flecs accross the server-client boundary.

## Sharing state

Before we begin, we need to have a record of flecs that we can use to send their states to the client.

To create this record of flecs, We'll follow a file hierarchy like this:

```
shared
├─ flecs
└─ remotes
```

::: tip Prerequisites

You should have your `remotes` set up in order to use `Teisu.server` properly.

You can use `RemoteEvent` instances, or if you're a big fan of open source libraries you can use the following:

- [Remo](https://github.com/littensy/remo)

- [Blink](https://github.com/1Axen/blink)

- [Zap](https://github.com/red-blox/zap)

- [ByteNet](https://github.com/ffrostfall/ByteNet)
:::

Your `flecs` should be a module that looks something like this:

```luau
local Teisu = require(game.ReplicatedStorage.Teisu)

local flec = Teisu.flec

return {
    todos = flec({} :: { string }),
    count = flec(0),
}
```

You'll also need two remote events:

- `sync(player: Player, payload: SyncPayload)` This remote event will fire from server to `player` with `payload`, a table that contains the full state and state changes.

- `hydrate()` This remote event will fire from a client to the server once they're ready to receive state from the server.

Now that we have that out of the way, it's time to create a `server` object that sends state to the client.

## Creating a server

You should call `Teisu.server()` on the server when your game starts up, and pass in your flecs to sync with the client. Use the `remotes` we've got set up earlier to broadcast state updates, and send the initial state to players upon request.

```luau
local Teisu = require(game.ReplicatedStorage.Teisu)
local flecs = require(game.ReplicatedStorage.flecs)
local remotes = require(game.ReplicatedStorage.remotes)

local server = Teisu.server

local syncer = server({ flecs = flecs })

syncer:connect(function(player, payload)
    remotes.sync:fire(player, payload)
end)

remotes.hydrate:connect(function(player)
    syncer:hydrate(player)
end)
```

## Creating a client

Now that we've got the server all set up, it's time to do the same for the client.

Call `Teisu.client()` when the client initializes in the game, and pass in your flecs.

```luau
local Teisu = require(game.ReplicatedStorage.Teisu)
local flecs = require(game.ReplicatedStorage.flecs)
local remotes = require(game.ReplicatedStorage.remotes)

local client = Teisu.client
local syncer = client({ flecs = flecs })

remotes.sync:connect(function(payload)
    -- `Teisu.client()` returns a sync object that only has one function: `:sync()`. 
    -- This function will be used to apply incoming state changes to our flecs.
    syncer:sync(payload)
end)

-- Requests the initial state from the server when the client joins the game.
-- Before this runs, the client uses the flecs' default values.
remotes.hydrate:fire()
```
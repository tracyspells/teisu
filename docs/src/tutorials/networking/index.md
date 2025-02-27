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

Your `flecs` should be a module that looks something like this:

```luau
local Teisu = require(game.ReplicatedStorage.Teisu)

local flec = Teisu.flec

return {
    todos = flec({} :: { string }),
    count = flec(0),
}
```

Now that we have that out of the way, it's time to create a `server` object that sends state to the client.

## Creating a server

`Teisu.server`

# Installation

## Wally

`Teisu` can be installed with [Wally](https://wally.run/), a package manager for Roblox.

Inside your `wally.toml`, add the following:

```toml title = "wally.toml"
[package]
name = "your_name/your_project"
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]
Teisu = "tracyspells/teisu@VERSION"
```

In your terminal, run the following code:

```bash
wally install
```
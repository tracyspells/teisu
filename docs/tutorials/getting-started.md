# Installation

## Wally

`Teisu` can be installed with [Wally](https://wally.run/), a package manager for Roblox.

Inside your `wally.toml`, add the following:

```toml title = "wally.toml" {8}
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

## GitHub Releases

Alternatively, you can get `Teisu`'s  `.rbxm` file from the [GitHub Releases page](https://github.com/tracyspells/teisu/releases).

## Why Teisu?

I wanted to make a reactive library just for fun and to gain experience. 

Not only that, but I wanted to take two libraries that I enjoyed using:

- [Vide](https://centau.github.io/vide/)

- [Charm](https://github.com/littensy/charm)

...and combine them into one. I added some changes and quality of life improvements.
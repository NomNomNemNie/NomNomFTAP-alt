# NomNomFTAP-alt

Canonical The Wourld-style Obsidian build for private Roblox/FTAP development. The Wourld is the base script and UI style; NoName, XOCO, and NoName-Apple are comparison sources whose stronger/missing features are integrated directly into Wourld-style sections.

## Usage

Use `Loader.lua` as the single runtime entrypoint:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NomNomNemNie/NomNomFTAP-alt/main/Loader.lua", true))()
```

`NomNom.lua` remains as a compatibility wrapper for older paste-run links. It simply loads `Loader.lua` from the same GitHub raw branch.

## Module layout

- `Loader.lua` is the only real entrypoint. It initializes Core, builds the canonical Wourld-style UI, and registers each direct feature section.
- `modules/Core.lua` owns rerun cleanup, shared services, remotes, character refresh, helper functions, tracked connections, tracked instances, task cleanup, and feature primitives.
- `modules/UI.lua` creates the Obsidian window/tabs and exposes the shared group helper.
- `modules/Gucci.lua` registers Home, Protection, Gucci, anti-explosion, anti-kick, shuriken anti-kick, and delete-legs controls.
- `modules/Combat.lua` registers grab, line, aura, and combat controls.
- `modules/Movement.lua` registers movement and world/player controls.
- `modules/Visuals.lua` registers camera, ESP, and lighting controls.
- `modules/Toys.lua` registers toy utilities and line color controls.
- `modules/Teleports.lua` registers map and player teleport controls.
- `modules/Settings.lua` registers cleanup, safety, and keybind controls.
- `modules/Protection.lua` is a compatibility module name; protection controls are currently registered by `modules/Gucci.lua` so Gucci/protection state stays together.

## Loader strategy

Roblox executors usually cannot `require` local files from a checked-out repository. For practical executor compatibility, `Loader.lua` fetches each module through `game:HttpGet` from GitHub raw URLs, compiles it with `loadstring`, and then calls module `init`/`register` functions.

The module files are still source-of-truth references in this repo. Keeping them separate makes review and maintenance easier while the loader remains paste-run compatible in executor environments.

## Standalone compatibility

`NomNom.lua` is intentionally small and not a second implementation. It exists only as a convenience wrapper:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/NomNomNemNie/NomNomFTAP-alt/main/NomNom.lua", true))()
```

That wrapper then loads `Loader.lua`.

## Integrated tabs

- Home
- Protection / Gucci
- Combat / Grab
- Player
- Visuals
- Toys / Utility
- Teleports / Map
- Settings

## Source summary

`Source/Strong/The Wourld` is canonical. `Source/Strong/NoName`, `Source/Strong/XOCO`, and `Source/Strong/NoName-Apple` were compared against it and only selected stronger/missing features were integrated. See `STRONG_COMPARISON.md` for the full source comparison and integration notes.

## Safety notes

- No lazy source-pack buttons or equal-source pack switching.
- No encoded payload pack loader or encoded chunk table structure.
- No automatic public-chat send, startup room spam, or public-chat advertisement logic.
- No absolute local workstation paths are required by repo files.

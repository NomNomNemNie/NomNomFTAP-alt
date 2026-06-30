# NomNomFTAP-alt

Unified Wourld-style Obsidian build for private Roblox/FTAP development.

## Usage

Paste-run `NomNom.lua`. The script loads the Obsidian UI, opens `NomNom FTAP Alt • Wourld Unified`, and exposes the integrated controls directly. Right Control toggles the Obsidian window when supported by the UI library.

## Architecture

`NomNom.lua` is a standalone synthesized script, not a pack loader.

- Wourld UI/UX is used as the base style.
- NoName and XOCO feature concepts are integrated directly into Wourld-style tabs and groupboxes.
- Shared helpers manage remotes, character refresh, toy spawning, network ownership, notifications, tracked connections, tracked instances, task loops, respawn handling, and rerun cleanup.
- The previous runtime is cleaned before a new paste-run session starts.

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

See `STRONG_COMPARISON.md` for the full source comparison and integration notes.

## Safety notes

- No lazy source-pack buttons.
- No encoded payload pack loader or encoded chunk table structure.
- No automatic public-chat send, startup room spam, or public-chat advertisement logic.
- No absolute local workstation paths are required by repo files.

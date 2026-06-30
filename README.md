# NomNom FTAP Alt - The Wourld Obsidian Base

This alt repository contains the generated `NomNom.lua` for the NomNom alt target.

## Architecture

`NomNom.lua` uses `Source/Strong/The Wourld` as the real base script. The Wourld still creates its own Obsidian window, tabs, mechanics, settings, and runtime behavior.

The generator inserts one additional Obsidian tab into The Wourld's tab table:

- `NomNom Packs` - an in-window pack management tab.

Inside that tab, the build adds:

- `Load NoName Pack` - manually decodes and runs the embedded `Source/Strong/NoName` payload.
- `Load XOCO Pack` - manually decodes and runs the embedded `Source/Strong/XOCO` payload.
- `Print Pack Status` - prints the pack summaries and recent loader status messages.
- `Reset Load Markers` - clears the lazy-loader markers so a pack can be attempted again without forcing its internals to unload.

## Lazy payload strategy

`NoName` and `XOCO` are not pasted into The Wourld's top-level scope. They are base64-encoded into chunk arrays and decoded only from the Obsidian button callbacks. This avoids malformed-string fragility and avoids adding large pack bodies to the same top-level local/register scope as The Wourld.

## Public-room message policy

The build does not auto-send public-room startup messages. The visible base source is sanitized for known public-room API identifiers, and decoded extra packs are sanitized immediately before compilation.

## Rebuild

Run `_roo_build_nomnom_alt.py` from this repository or from the workspace root to regenerate `NomNom.lua` and this README from the current `Source/Strong` files.

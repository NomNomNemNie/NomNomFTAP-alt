# NomNom FTAP Alt - Merged 3-Pack Build

This alt repository contains the standalone merged `NomNom.lua` launcher for the NomNom alt target.

## What is merged

`NomNom.lua` embeds all three `Source/Strong` packs as lazy base64 chunk arrays:

- `The Wourld Base` - base pack with Defense, Target, Visuals, Server, Misc, Keybinds, Owner, Credits, and UI settings.
- `NoName Pack` - defense, grab tools, player controls, target tools, keybinds, visuals, misc, owner/config, and lag-related sections.
- `XOCO Pack` - defense, target, grab, player, misc, keybinds, and visuals.

The launcher itself is the only code that runs on paste. Each pack is decoded, sanitized, compiled, and executed only when its load button is pressed.

## Resonance-inspired organization

The reference page at `https://marshelx.github.io/resonance-features/` uses an Obsidian-style layout with tabs such as Home, Combat, Visual, Misc, Invincibility, Toys, Player, Target, Keybinds, Lists, Auto-Clicker, and Settings. Its group boxes include areas such as Auras, Grabs, Antis, Counter-attack, ESP, Game Tweaks, Teleporting, Players, Themes, Configuration, and Notifications.

This build adapts that structure into these launcher categories:

- Home
- Combat
- Movement
- Visuals
- Utility
- Protection/Gucci
- Teleports/Map
- Settings
- Search/Favorites/Status

## Safety and rerun behavior

Automatic public-room message behavior is blocked by the launcher sanitizer before any selected pack runs. The launcher does not send startup public-room messages.

The build includes rerun cleanup for the launcher UI. Re-pasting the script removes the previous launcher instance before creating a new one. Pack internals still use their own runtime/UI behavior after being manually loaded.

## Usage

Paste-run `NomNom.lua`, then choose a pack from the launcher. Right Control toggles the launcher visibility.

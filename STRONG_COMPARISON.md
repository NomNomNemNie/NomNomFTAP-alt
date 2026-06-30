# Strong source comparison

This document records the full rebuild comparison used for `NomNom.lua`. The final script is a direct Wourld-style Obsidian synthesis, not a pack loader.

## Source roles

| Source | UI style | Primary strengths | Integrated outcome |
| --- | --- | --- | --- |
| `Source/Strong/The Wourld` | Obsidian-style UI and Wourld UX conventions | Defense/protection, Gucci flow, target/server sections, keybind/settings structure, rerun cleanup marker | Used as the final UX standard and naming model. |
| `Source/Strong/NoName` | Orion tabs: Defense, Grabs, Player, Target, Keybinds, Visual, Misc, Owner, Settings | Anti-grab, AntiKick shuriken/item, AntiBlob, AntiPaint, AntiBurn, AntiVoid, super strength, infinity line extend, grab modifiers, auras, player movement, ESP/PCLD ESP, map points | Feature concepts reimplemented inside matching Wourld/Obsidian tabs with shared helpers and tracked connections. |
| `Source/Strong/XOCO` | Solaris tabs: defense, target, grab, player, misc, keybinds, visuals | Multiple AntiGrab versions, AntiBlob aura/drop logic, Gucci/invisible Gucci/watchdogs, platform TP, input-lag item loops, auto reset/leave correction handlers, paint cleanup, delete legs, anti-burn | Stronger Gucci/protection and utility ideas integrated cleanly without copying giant top-level generated blocks. |

## Feature comparison

### UI structure

- Wourld is the standard for the final UX because it already follows an Obsidian-style window/tab/groupbox model.
- NoName and XOCO feature families were mapped into: Home, Protection / Gucci, Combat / Grab, Player, Visuals, Toys / Utility, Teleports / Map, and Settings.
- The final build has no lazy source-pack buttons, encoded chunk table, base64 source payloads, or lazy pack execution buttons.

### Protection / Gucci

- Wourld contributes the base protection/Gucci concept and Obsidian interaction style.
- NoName contributes AntiGrab, AntiKick item/shuriken concepts, AntiBlob, AntiPaint, AntiBurn, AntiVoid, AntiBarrier, anti-loop-kill map recovery, and delete-legs recovery.
- XOCO contributes verified-style anti-grab loops, anti-blob aura/drop, platform/high safety concepts, invisible/auto Gucci watchdog ideas, correction reset, and stronger cleanup around Gucci toys.
- Final synthesis includes verified protection, anti steal-seat, anti massless/blob physics, recovery lock, anti blob/drop aura, anti paint, anti burn, no void despawn, bind Gucci, auto Gucci watchdog, anti-destroy stabilizer, high/safe patrol, anti-kick item attach, and delete legs.

### Combat / grab / target

- NoName has the richest grab set: super strength, infinity line extend, responsiveness/massless grab, spin/ragdoll grab, RGB/invisible line, fling/click aura, blob bring/drop.
- XOCO overlaps on target/grab and adds aura-oriented blob pressure.
- Final synthesis reimplements these concepts with one set of remotes and connection guards instead of concatenating source chunks.

### Movement / player

- NoName contributes WalkSpeed multiplier, infinite jump, ocean walk, barrier toggles, preserve/respawn concepts.
- XOCO contributes correction reset and high/platform safety.
- Final synthesis includes WalkSpeed, Infinity Jump, stop velocity, ragdoll pulse, ocean walk, anti barrier, and correction reset.

### Visuals

- NoName contributes icon ESP, PCLD ESP, FOV, and third-person handling.
- XOCO contributes visuals tab organization.
- Final synthesis includes third person, FOV, player ESP, PCLD ESP, fullbright, low graphics, and camera reset.

### Toys / utility

- NoName and XOCO both contain toy-spawn workflows for protection and input-lag mitigation.
- Final synthesis uses a shared `spawnToy` helper, input guard toy cycle, blobman/tractor spawns, NomNom toy cleanup, line color pulse, invisible line, and base line restore.

### Teleport / map

- NoName map points were preserved and renamed to readable house labels.
- XOCO platform/high safety ideas were moved into keybind/settings and patrol controls.
- Final synthesis includes selected house teleport, loop selected teleport, random house patrol, teleport to nearest, and nearest network bring.

### Settings / cleanup / recovery

- All three scripts had previous rerun/public-chat fixes carried forward.
- Final runtime tracks connections, tasks, and instances, cleans a previous run before mounting, refreshes character state on respawn, and uses low-noise notification cooldowns.
- No automatic public-chat APIs or startup public chat sends are used.

## Source fixes applied

- Wourld: retained rerun/register scope markers; public chat announcement remains disabled.
- NoName: retained rerun cleanup; fixed public chat service removal, `character` raycast typo, `shi`/`HRP` typo, shuriken name typo, and untracked PCLD ESP connection.
- XOCO: retained rerun cleanup and added register-scope wrapper if missing; fixed startup loaded-message auto call removal, `MouseMouseBehavior` typo, several callback `Value` vs `v` mistakes, and a malformed notification call.

## Final integration strategy

The final `NomNom.lua` is not a concatenation. It extracts feature concepts and reimplements them through shared helpers for remotes, character refresh, toy spawn, notifications, cleanup, loops, and Obsidian controls. This keeps top-level local/register pressure low and makes the script paste-run compatible.
